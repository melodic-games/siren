// Made with Amplify Shader Editor v1.9.0.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Sand Terrain"
{
	Properties
	{
		_RippleSteepnessPower("Ripple Steepness Power", Float) = 1
		_RippleStrength("Ripple Strength", Range( 0 , 1)) = 0.2
		_RippleSize("Ripple Size", Float) = 50
		[SingleLineTexture]_RipplesSteepTexture("Ripples Steep Texture", 2D) = "bump" {}
		[SingleLineTexture]_RipplesShallowTexture("Ripples Shallow Texture", 2D) = "bump" {}
		_ColorTerrain("Color Terrain", Color) = (0.9137255,0.5450981,0.5254902,0)
		_OceanSpecularPower("Ocean Specular Power", Float) = 64
		_OceanSpecularStrength("Ocean Specular Strength", Float) = 0.5
		_OceanSpecularColor("Ocean Specular Color", Color) = (1,0.7843137,0.772549,0)
		_RimColor("Rim Color", Color) = (1,0.5647059,0.5411765,0)
		_RimStrength("Rim Strength", Float) = 1
		_RimPower("Rim Power", Float) = 8
		_GrainSize("Grain Size", Float) = 16
		_GrainStrength("Grain Strength", Range( 0 , 1)) = 0.2
		_GrainFalloffDistance("Grain Falloff Distance", Range( 0 , 10000)) = 1000
		_GrainFalloffPower("Grain Falloff Power", Range( 0 , 1)) = 0.1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			half ase_vertexTangentSign;
			float2 uv_texcoord;
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

		uniform sampler2D _RipplesSteepTexture;
		uniform float _RippleSize;
		uniform sampler2D _RipplesShallowTexture;
		uniform float _RippleSteepnessPower;
		uniform float _RippleStrength;
		uniform float _GrainSize;
		uniform float _GrainStrength;
		uniform float _GrainFalloffDistance;
		uniform float _GrainFalloffPower;
		uniform float4 _ColorTerrain;
		uniform float _RimStrength;
		uniform float _RimPower;
		uniform float4 _RimColor;
		uniform float _OceanSpecularPower;
		uniform float _OceanSpecularStrength;
		uniform float4 _OceanSpecularColor;


		float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }

		float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }

		float snoise( float3 v )
		{
			const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
			float3 i = floor( v + dot( v, C.yyy ) );
			float3 x0 = v - i + dot( i, C.xxx );
			float3 g = step( x0.yzx, x0.xyz );
			float3 l = 1.0 - g;
			float3 i1 = min( g.xyz, l.zxy );
			float3 i2 = max( g.xyz, l.zxy );
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy;
			float3 x3 = x0 - 0.5;
			i = mod3D289( i);
			float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
			float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
			float4 x_ = floor( j / 7.0 );
			float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
			float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 h = 1.0 - abs( x ) - abs( y );
			float4 b0 = float4( x.xy, y.xy );
			float4 b1 = float4( x.zw, y.zw );
			float4 s0 = floor( b0 ) * 2.0 + 1.0;
			float4 s1 = floor( b1 ) * 2.0 + 1.0;
			float4 sh = -step( h, 0.0 );
			float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
			float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
			float3 g0 = float3( a0.xy, h.x );
			float3 g1 = float3( a0.zw, h.y );
			float3 g2 = float3( a1.xy, h.z );
			float3 g3 = float3( a1.zw, h.w );
			float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
			g0 *= norm.x;
			g1 *= norm.y;
			g2 *= norm.z;
			g3 *= norm.w;
			float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
			m = m* m;
			m = m* m;
			float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
			return 42.0 * dot( m, px);
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.ase_vertexTangentSign = v.tangent.w;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 temp_output_18_0_g210 = ase_worldNormal;
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 break14_g213 = ( cross( ase_worldNormal , ase_worldTangent ) * i.ase_vertexTangentSign );
			float3 appendResult12_g213 = (float3(ase_worldTangent.x , break14_g213.x , ase_worldNormal.x));
			float2 temp_output_11_0_g210 = ( i.uv_texcoord * _RippleSize );
			float dotResult3_g210 = dot( temp_output_18_0_g210 , float3(0,0,1) );
			float3 lerpResult3_g211 = lerp( UnpackNormal( tex2D( _RipplesSteepTexture, temp_output_11_0_g210 ) ) , UnpackNormal( tex2D( _RipplesShallowTexture, temp_output_11_0_g210 ) ) , pow( saturate( dotResult3_g210 ) , _RippleSteepnessPower ));
			float3 normalizeResult5_g211 = normalize( lerpResult3_g211 );
			float3 temp_output_18_0_g213 = normalizeResult5_g211;
			float dotResult19_g213 = dot( appendResult12_g213 , temp_output_18_0_g213 );
			float3 appendResult16_g213 = (float3(ase_worldTangent.y , break14_g213.y , ase_worldNormal.y));
			float dotResult21_g213 = dot( appendResult16_g213 , temp_output_18_0_g213 );
			float3 appendResult17_g213 = (float3(ase_worldTangent.z , break14_g213.z , ase_worldNormal.z));
			float dotResult22_g213 = dot( appendResult17_g213 , temp_output_18_0_g213 );
			float4 appendResult23_g213 = (float4(dotResult19_g213 , dotResult21_g213 , dotResult22_g213 , 0.0));
			float3 lerpResult3_g212 = lerp( temp_output_18_0_g210 , appendResult23_g213.xyz , _RippleStrength);
			float3 normalizeResult5_g212 = normalize( lerpResult3_g212 );
			float3 ase_worldPos = i.worldPos;
			float3 temp_output_6_0_g224 = ( ase_worldPos * _GrainSize );
			float simplePerlin3D14_g224 = snoise( ( temp_output_6_0_g224 + float3(1349,6391,2465) ) );
			simplePerlin3D14_g224 = simplePerlin3D14_g224*0.5 + 0.5;
			float simplePerlin3D15_g224 = snoise( ( temp_output_6_0_g224 + float3(7827,2945,5698) ) );
			simplePerlin3D15_g224 = simplePerlin3D15_g224*0.5 + 0.5;
			float simplePerlin3D16_g224 = snoise( ( temp_output_6_0_g224 + float3(5282,4216,3212) ) );
			simplePerlin3D16_g224 = simplePerlin3D16_g224*0.5 + 0.5;
			float4 appendResult17_g224 = (float4(simplePerlin3D14_g224 , simplePerlin3D15_g224 , simplePerlin3D16_g224 , 0.0));
			float4 normalizeResult34_g224 = normalize( appendResult17_g224 );
			float temp_output_1_0_g225 = 0.0;
			float3 lerpResult3_g226 = lerp( normalizeResult5_g212 , normalizeResult34_g224.xyz , ( _GrainStrength * ( 1.0 - pow( ( ( distance( _WorldSpaceCameraPos , ase_worldPos ) - temp_output_1_0_g225 ) / ( _GrainFalloffDistance - temp_output_1_0_g225 ) ) , _GrainFalloffPower ) ) ));
			float3 normalizeResult5_g226 = normalize( lerpResult3_g226 );
			float3 Normals169 = normalizeResult5_g226;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult5_g239 = dot( ( float3(1,0.3,1) * Normals169 ) , ase_worldlightDir );
			float LightData172 = ( saturate( ( dotResult5_g239 * 4.0 ) ) * ase_lightAtten );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			UnityGI gi159 = gi;
			float3 diffNorm159 = ase_worldNormal;
			gi159 = UnityGI_Base( data, 1, diffNorm159 );
			float3 indirectDiffuse159 = gi159.indirect.diffuse + diffNorm159 * 0.0001;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 temp_output_2_0_g237 = Normals169;
			float fresnelNdotV15_g237 = dot( temp_output_2_0_g237, ase_worldViewDir );
			float fresnelNode15_g237 = ( 0.0 + _RimStrength * pow( 1.0 - fresnelNdotV15_g237, _RimPower ) );
			float3 normalizeResult4_g236 = normalize( ( ase_worldViewDir + ase_worldlightDir ) );
			float dotResult6_g236 = dot( Normals169 , normalizeResult4_g236 );
			float4 Specular176 = ( saturate( max( ( fresnelNode15_g237 * _RimColor ) , ( ( pow( saturate( dotResult6_g236 ) , _OceanSpecularPower ) * _OceanSpecularStrength ) * _OceanSpecularColor ) ) ) * LightData172 );
			c.rgb = ( ( float4( ( ( LightData172 * ase_lightColor.rgb ) + indirectDiffuse159 ) , 0.0 ) * _ColorTerrain ) + Specular176 ).rgb;
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
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.x = customInputData.ase_vertexTangentSign;
				o.customPack1.yz = customInputData.uv_texcoord;
				o.customPack1.yz = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.ase_vertexTangentSign = IN.customPack1.x;
				surfIN.uv_texcoord = IN.customPack1.yz;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19002
1922;23;1920;1059;4385.948;847.245;2.965977;True;False
Node;AmplifyShaderEditor.CommentaryNode;80;-3015.894,286.9253;Inherit;False;1635.906;312.7277;;4;124;169;122;30;Normals;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;30;-2963.227,335.5919;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;122;-2616.596,373.9987;Inherit;False;Sand Terrain Ripples Normal;0;;210;6ed8ef22b18433949a2efc526b57ab12;0;1;18;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;124;-2161.833,377.7904;Inherit;False;Sand Terrain Grain Normal;15;;224;37f47e9c36ddce14d8e40d0ee62cb800;0;1;20;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;64;-3016.722,708.6507;Inherit;False;1652.74;389.8334;;5;165;172;175;104;184;Light Data;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;169;-1680.252,367.3564;Inherit;False;Normals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;93;-3009.872,1171.915;Inherit;False;1649;317.9464;;8;176;178;177;92;91;151;182;171;Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;165;-2776.135,881.2961;Inherit;False;169;Normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightAttenuation;104;-2444.948,981.0936;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;171;-2918.427,1308.809;Inherit;False;169;Normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;184;-2453.651,820.6941;Inherit;False;JourneyLambert;-1;;239;1c5ef3f64a9db8d42b8593728b2d6860;0;1;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;182;-2612.265,1370.449;Inherit;False;Sand Terrain Ocean Specular;7;;236;5898ff5fa4e14ba42940e8fcbe657e2c;0;1;7;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;175;-1945.752,866.7718;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;151;-2610.762,1234.249;Inherit;False;Sand Terrain Rim Lighting;11;;237;0eda5e26ec7dfb44f91b09cd751bb2b8;0;1;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;91;-2271.229,1283.739;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;172;-1626.452,867.4645;Inherit;False;LightData;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;156;-915.7093,706.4875;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;92;-2068.275,1239.618;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-2090.783,1378.978;Inherit;False;172;LightData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;173;-934.5043,517.443;Inherit;False;172;LightData;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;178;-1822.077,1297.319;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;170;-568.3694,565.0903;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;159;-659.1457,906.7454;Inherit;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;176;-1593.036,1312.263;Inherit;False;Specular;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-171.7867,739.612;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;95;-222.5822,1168.47;Inherit;False;Property;_ColorTerrain;Color Terrain;6;0;Create;True;0;0;0;False;0;False;0.9137255,0.5450981,0.5254902,0;0.6666667,0.3788889,0.1999999,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;179;269.2328,1301.807;Inherit;False;176;Specular;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;160;277.4301,951.9128;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;675.2074,1133.995;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;870.2872,894.0468;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Sand Terrain;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;122;18;30;0
WireConnection;124;20;122;0
WireConnection;169;0;124;0
WireConnection;184;1;165;0
WireConnection;182;7;171;0
WireConnection;175;0;184;0
WireConnection;175;1;104;0
WireConnection;151;2;171;0
WireConnection;91;0;151;0
WireConnection;91;1;182;0
WireConnection;172;0;175;0
WireConnection;92;0;91;0
WireConnection;178;0;92;0
WireConnection;178;1;177;0
WireConnection;170;0;173;0
WireConnection;170;1;156;1
WireConnection;176;0;178;0
WireConnection;158;0;170;0
WireConnection;158;1;159;0
WireConnection;160;0;158;0
WireConnection;160;1;95;0
WireConnection;164;0;160;0
WireConnection;164;1;179;0
WireConnection;0;13;164;0
ASEEND*/
//CHKSM=821214F3C5F9BB3589E671077BD7DC36ACC7F74C