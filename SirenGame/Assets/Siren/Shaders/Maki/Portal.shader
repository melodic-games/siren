// Made with Amplify Shader Editor v1.9.0.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Maki/Portal"
{
	Properties
	{
		_MainTexture("Main Texture", 2D) = "white" {}
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		_ColorNoiseScale("Color Noise Scale", Range( 0 , 128)) = 12
		_ColorNoiseSpeed("Color Noise Speed", Range( 0 , 4)) = 0.2
		_ColorSwirlinessIntensity("Color Swirliness Intensity", Range( 0 , 0.2)) = 0.015
		_WhiteEdgeScale("White Edge Scale", Range( 1 , 32)) = 2.1
		_WhiteEdgeInnerScale("White Edge Inner Scale", Range( 0 , 1)) = 0.54
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" }
		Cull Off
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "Portal.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#include "Assets/Siren/Shaders/Snoise.cginc"
		#pragma surface surf StandardCustomLighting keepalpha noshadow 
		struct Input
		{
			float3 worldPos;
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

		uniform float _ColorNoiseScale;
		uniform float _ColorNoiseSpeed;
		uniform float _WhiteEdgeScale;
		uniform float _WhiteEdgeInnerScale;
		uniform float _ColorSwirlinessIntensity;
		uniform sampler2D _MainTexture;
		uniform float _Cutoff = 0.5;


		inline float snoise_external62( float3 In )
		{
			return snoise(In);
		}


		float3 swirlinessEdgesColorAddition( float swirlinessLength, float3 color )
		{
			if (swirlinessLength>0.35) {
				color += float3(1,1,1)*0.1;
			}
			if (swirlinessLength>0.425) {
				color += float3(1,1,1)*0.3;
			}
			return color;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float4 appendResult42 = (float4(_WorldSpaceCameraPos , 1.0));
			float4 rayOrigin47 = mul( unity_WorldToObject, appendResult42 );
			float3 rayOrigin9 = rayOrigin47.xyz;
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float4 normalizeResult46 = normalize( ( float4( ase_vertex3Pos , 0.0 ) - rayOrigin47 ) );
			float4 rayDir57 = normalizeResult46;
			float3 rayDir9 = rayDir57.xyz;
			float mulTime11 = _Time.y * 0.5;
			float time68 = mulTime11;
			float time9 = time68;
			float4 localraymarch9 = raymarch( rayOrigin9 , rayDir9 , time9 );
			float4 break178 = localraymarch9;
			float opacity180 = break178.w;
			float3 appendResult179 = (float3(break178.x , break178.y , break178.z));
			float3 rayPos55 = appendResult179;
			float3 break59 = rayPos55;
			float2 appendResult61 = (float2(break59.x , break59.y));
			float2 uv64 = appendResult61;
			float2 break105 = uv64;
			float2 appendResult108 = (float2(break105.x , ( break105.y * ( 3.0 / 2.0 ) )));
			float2 nUv111 = ( appendResult108 * _ColorNoiseScale );
			float3 appendResult81 = (float3(nUv111 , ( ( sin( time68 ) + ( time68 * 3.0 ) ) * _ColorNoiseSpeed )));
			float3 In62 = appendResult81;
			float localsnoise_external62 = snoise_external62( In62 );
			float n88 = ( ( localsnoise_external62 + 1.0 ) * 0.5 );
			float2 temp_output_93_0 = ( uv64 * _WhiteEdgeScale );
			float3 temp_cast_3 = (1.0).xxx;
			float2 break153 = ( temp_output_93_0 * _WhiteEdgeInnerScale );
			float swirliness148 = ( ( n88 - 0.5 ) * _ColorSwirlinessIntensity );
			float2 appendResult155 = (float2(break153.x , ( break153.y + ( swirliness148 * 16.0 ) )));
			float swirlinessLength167 = length( appendResult155 );
			float2 break117 = uv64;
			float2 appendResult125 = (float2(( break117.x / 1.0 ) , break117.y));
			float2 break142 = ( appendResult125 + 0.5 );
			float2 appendResult140 = (float2(( swirliness148 + break142.x ) , break142.y));
			float2 imageUv128 = appendResult140;
			float3 color167 = tex2D( _MainTexture, imageUv128 ).rgb;
			float3 localswirlinessEdgesColorAddition167 = swirlinessEdgesColorAddition( swirlinessLength167 , color167 );
			float3 ifLocalVar95 = 0;
			if( ( n88 + pow( length( temp_output_93_0 ) , 10.0 ) ) > 1.0 )
				ifLocalVar95 = temp_cast_3;
			else if( ( n88 + pow( length( temp_output_93_0 ) , 10.0 ) ) < 1.0 )
				ifLocalVar95 = localswirlinessEdgesColorAddition167;
			c.rgb = ifLocalVar95;
			c.a = 1;
			clip( opacity180 - _Cutoff );
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
480;911;1633;488;1845.865;-1571.005;1.649767;True;False
Node;AmplifyShaderEditor.CommentaryNode;65;-1407.393,-345.4989;Inherit;False;1770.635;565.3481;Ray march;16;180;55;179;178;9;69;57;46;45;48;44;47;41;43;42;39;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;39;-1357.393,-209.4441;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;42;-1091.069,-181.3002;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldToObjectMatrix;43;-1128.579,-295.4989;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-837.726,-184.1593;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;47;-653.5954,-190.8765;Inherit;False;rayOrigin;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;-1262.732,113.5075;Inherit;False;47;rayOrigin;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PosVertexDataNode;44;-1274.728,-53.47134;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;11;-1377.517,-483.8151;Inherit;False;1;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;45;-1016.916,-32.43645;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;68;-1158.872,-490.6257;Inherit;False;time;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;46;-828.3459,-45.24944;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;69;-615.5972,41.13226;Inherit;False;68;time;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;-639.9076,-70.91541;Inherit;False;rayDir;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;9;-354.3135,-108.659;Inherit;False;;4;File;3;True;rayOrigin;FLOAT3;0,0,0;In;;Inherit;False;True;rayDir;FLOAT3;0,0,0;In;;Inherit;False;True;time;FLOAT;0;In;;Inherit;False;raymarch;False;False;0;576844cf772941cdbecfd68ac35a5e0c;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;178;-136.0088,-115.4869;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;179;-8.008784,-118.4869;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;157.2355,-112.0826;Inherit;False;rayPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;66;-1414.878,292.2848;Inherit;False;767.7939;209;Ray pos to UV;4;56;59;61;64;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-1364.878,343.8576;Inherit;False;55;rayPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;59;-1177.507,342.2848;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;61;-1038.507,344.2848;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;112;-1419.738,569.7983;Inherit;False;1205.113;346.1976;UV for noise;8;105;107;110;108;109;111;170;67;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;170;-1377.049,704.9958;Inherit;False;295;189;Aspect Ratio;3;102;104;103;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;64;-871.0847,343.3114;Inherit;False;uv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-1370.049,746.9958;Inherit;False;Constant;_Float8;Float 8;0;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;67;-1388.738,609.7983;Inherit;False;64;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;104;-1367.049,821.9958;Inherit;False;Constant;_Float9;Float 9;0;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;102;-1222.049,763.9958;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;105;-1182.049,608.9958;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-1027.049,688.9958;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;89;-1424.693,961.483;Inherit;False;1748.335;338.3701;Noise;12;88;62;81;172;113;78;73;79;71;75;171;72;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;72;-1404.693,1078.853;Inherit;False;68;time;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-959.9835,796.585;Inherit;False;Property;_ColorNoiseScale;Color Noise Scale;2;0;Create;True;0;0;0;False;0;False;12;12;0;128;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;108;-856.0485,622.9958;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;171;-1369.949,1184.235;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;-603.0082,642.0814;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-1198.693,1129.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;71;-1197.693,1056.853;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;73;-989.6936,1091.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-438.6244,634.6539;Inherit;False;nUv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;79;-1100.136,1217.263;Inherit;False;Property;_ColorNoiseSpeed;Color Noise Speed;3;0;Create;True;0;0;0;False;0;False;0.2;0.2;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;-862.4192,1028.619;Inherit;False;111;nUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;78;-830.6937,1123.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;172;-362.6931,1032.853;Inherit;False;459.9999;223;Normalize 0 to 1;4;86;87;83;84;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-677.6936,1069.853;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;62;-511.8268,1071.309;Inherit;False;snoise(In);1;Create;1;True;In;FLOAT3;0,0,0;In;;Inherit;False;snoise_external;True;False;0;;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;84;-349.6931,1133.853;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;83;-175.693,1070.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-185.693,1182.853;Inherit;False;Constant;_Float3;Float 3;0;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;129;-1406.506,1738.827;Inherit;False;1646.448;388;Image UV;12;128;140;126;118;125;143;150;142;127;117;114;119;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;86;-22.69327,1108.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;149;-1414.406,1337.443;Inherit;False;855.0542;312;Swirliness;6;130;132;131;135;134;148;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-1356.506,1899.828;Inherit;False;64;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;88;122.6422,1102.141;Inherit;False;n;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;119;-1146.505,1808.827;Inherit;False;Constant;_AspectRatio;Aspect Ratio;0;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-1364.406,1387.443;Inherit;False;88;n;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;132;-1351.406,1482.444;Inherit;False;Constant;_Float13;Float 13;0;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;117;-1141.506,1892.828;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleSubtractOpNode;131;-1160.406,1424.443;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;135;-1195.406,1533.444;Inherit;False;Property;_ColorSwirlinessIntensity;Color Swirliness Intensity;4;0;Create;True;0;0;0;False;0;False;0.015;0.015;0;0.2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;118;-963.5049,1843.827;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;127;-820.5054,1985.828;Inherit;False;Constant;_Float12;Float 12;0;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;125;-812.5054,1875.827;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;134;-925.4072,1460.444;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;126;-595.5049,1900.828;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;148;-756.3541,1456.901;Inherit;False;swirliness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-1170.163,2210.979;Inherit;False;64;uv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-1278.164,2314.979;Inherit;False;Property;_WhiteEdgeScale;White Edge Scale;5;0;Create;True;0;0;0;False;0;False;2.1;2;1;32;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;142;-449.9058,1905.464;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-979.1626,2240.979;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;176;-1224.756,2411.137;Inherit;False;Property;_WhiteEdgeInnerScale;White Edge Inner Scale;6;0;Create;True;0;0;0;False;0;False;0.54;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;169;-893.306,2528.809;Inherit;False;1133.218;613.457;Sampled texture;11;167;162;144;155;145;152;156;159;153;157;160;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-531.207,1809.033;Inherit;False;148;swirliness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;143;-301.9056,1864.464;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;-867.1967,2750.521;Inherit;False;Constant;_Float7;Float 7;1;0;Create;True;0;0;0;False;0;False;16;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;175;-829.7557,2388.137;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;157;-882.1968,2658.521;Inherit;False;148;swirliness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;159;-676.1971,2695.521;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;153;-615.5125,2590.818;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;140;-145.9058,1898.464;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;128;34.51801,1896.639;Inherit;False;imageUv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;168;-295.8383,2174.629;Inherit;False;537.3832;317.3647;White edges;5;98;99;96;97;90;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;156;-489.5884,2654.46;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;97;-256.7357,2403.069;Inherit;False;Constant;_Float5;Float 5;0;0;Create;True;0;0;0;False;0;False;10;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;155;-327.5952,2589.976;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;90;-255.0097,2316.631;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;145;-704.0216,2919.362;Inherit;True;Property;_MainTexture;Main Texture;0;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;152;-654.5565,2812.788;Inherit;False;128;imageUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;144;-420.5988,2757.125;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;96;-84.73526,2351.069;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;162;-163.791,2622.174;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;99;-108.7354,2237.069;Inherit;False;88;n;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;167;-18.7953,2652.207;Inherit;False;if (swirlinessLength>0.35) {$	color += float3(1,1,1)*0.1@$}$if (swirlinessLength>0.425) {$	color += float3(1,1,1)*0.3@$}$return color@;3;Create;2;True;swirlinessLength;FLOAT;0;In;;Inherit;False;True;color;FLOAT3;0,0,0;In;;Inherit;False;swirlinessEdgesColorAddition;False;False;0;;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;98;89.26424,2301.069;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;100;268.8272,2553.917;Inherit;False;Constant;_Float6;Float 6;0;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;180;40.99122,19.51309;Inherit;False;opacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;181;472.9341,2405.763;Inherit;False;180;opacity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ConditionalIfNode;95;480.084,2512.692;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;818.3868,2239.946;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Maki/Portal;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Custom;0.5;True;False;0;True;TransparentCutout;;Geometry;All;18;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;False;0;5;False;;10;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;1;Include;;True;5b3053a266504e9e9de4870a5e515f88;Custom;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;42;0;39;0
WireConnection;41;0;43;0
WireConnection;41;1;42;0
WireConnection;47;0;41;0
WireConnection;45;0;44;0
WireConnection;45;1;48;0
WireConnection;68;0;11;0
WireConnection;46;0;45;0
WireConnection;57;0;46;0
WireConnection;9;0;47;0
WireConnection;9;1;57;0
WireConnection;9;2;69;0
WireConnection;178;0;9;0
WireConnection;179;0;178;0
WireConnection;179;1;178;1
WireConnection;179;2;178;2
WireConnection;55;0;179;0
WireConnection;59;0;56;0
WireConnection;61;0;59;0
WireConnection;61;1;59;1
WireConnection;64;0;61;0
WireConnection;102;0;103;0
WireConnection;102;1;104;0
WireConnection;105;0;67;0
WireConnection;107;0;105;1
WireConnection;107;1;102;0
WireConnection;108;0;105;0
WireConnection;108;1;107;0
WireConnection;109;0;108;0
WireConnection;109;1;110;0
WireConnection;75;0;72;0
WireConnection;75;1;171;0
WireConnection;71;0;72;0
WireConnection;73;0;71;0
WireConnection;73;1;75;0
WireConnection;111;0;109;0
WireConnection;78;0;73;0
WireConnection;78;1;79;0
WireConnection;81;0;113;0
WireConnection;81;2;78;0
WireConnection;62;0;81;0
WireConnection;83;0;62;0
WireConnection;83;1;84;0
WireConnection;86;0;83;0
WireConnection;86;1;87;0
WireConnection;88;0;86;0
WireConnection;117;0;114;0
WireConnection;131;0;130;0
WireConnection;131;1;132;0
WireConnection;118;0;117;0
WireConnection;118;1;119;0
WireConnection;125;0;118;0
WireConnection;125;1;117;1
WireConnection;134;0;131;0
WireConnection;134;1;135;0
WireConnection;126;0;125;0
WireConnection;126;1;127;0
WireConnection;148;0;134;0
WireConnection;142;0;126;0
WireConnection;93;0;91;0
WireConnection;93;1;94;0
WireConnection;143;0;150;0
WireConnection;143;1;142;0
WireConnection;175;0;93;0
WireConnection;175;1;176;0
WireConnection;159;0;157;0
WireConnection;159;1;160;0
WireConnection;153;0;175;0
WireConnection;140;0;143;0
WireConnection;140;1;142;1
WireConnection;128;0;140;0
WireConnection;156;0;153;1
WireConnection;156;1;159;0
WireConnection;155;0;153;0
WireConnection;155;1;156;0
WireConnection;90;0;93;0
WireConnection;144;0;145;0
WireConnection;144;1;152;0
WireConnection;96;0;90;0
WireConnection;96;1;97;0
WireConnection;162;0;155;0
WireConnection;167;0;162;0
WireConnection;167;1;144;0
WireConnection;98;0;99;0
WireConnection;98;1;96;0
WireConnection;180;0;178;3
WireConnection;95;0;98;0
WireConnection;95;1;100;0
WireConnection;95;2;100;0
WireConnection;95;4;167;0
WireConnection;0;10;181;0
WireConnection;0;13;95;0
ASEEND*/
//CHKSM=EAC66C568DC9F424411982BA0E97335C8976C3B4