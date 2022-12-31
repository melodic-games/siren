// Made with Amplify Shader Editor v1.9.1.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Maki/Planar Reflection Water"
{
	Properties
	{
		_Scale("Scale", Range( 0.01 , 1)) = 1
		_EdgeWidth("Edge Width", Range( 0 , 0.1)) = 0.1
		_VoronoiSpeed("Voronoi Speed", Range( 0 , 1)) = 0
		[Toggle]_BigNoiseEnable("Big Noise Enable", Float) = 1
		_BigNoiseIntensity("Big Noise Intensity", Range( 0 , 1)) = 0
		_BigNoiseScale("Big Noise Scale", Range( 0 , 4)) = 2.473072
		_BigNoiseSpeed("Big Noise Speed", Range( 0 , 1)) = 0.2
		[Toggle]_SmallNoiseEnable("Small Noise Enable", Float) = 1
		_SmallNoiseIntensity("Small Noise Intensity", Range( 0 , 1)) = 0
		_SmallNoiseScale("Small Noise Scale", Range( 0 , 4)) = 2.473072
		_SmallNoiseSpeed("Small Noise Speed", Range( 0 , 1)) = 0.2
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 4.6
		#pragma surface surf StandardCustomLighting keepalpha addshadow fullforwardshadows 
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

		uniform float _VoronoiSpeed;
		uniform float _Scale;
		uniform float _BigNoiseEnable;
		uniform float _BigNoiseScale;
		uniform float _BigNoiseSpeed;
		uniform float _BigNoiseIntensity;
		uniform float _SmallNoiseEnable;
		uniform float _SmallNoiseScale;
		uniform float _SmallNoiseSpeed;
		uniform float _SmallNoiseIntensity;
		uniform float _EdgeWidth;


		float2 voronoihash47( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi47( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mg = 0;
			for ( int j = -2; j <= 2; j++ )
			{
				for ( int i = -2; i <= 2; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash47( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
					float d = 0.707 * sqrt(dot( r, r ));
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			
			 		}
			 	}
			}
			return F1;
		}


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


		float2 voronoihash74( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi74( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mg = 0;
			for ( int j = -2; j <= 2; j++ )
			{
				for ( int i = -2; i <= 2; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash74( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
					float d = 0.707 * sqrt(dot( r, r ));
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			
			 		}
			 	}
			}
			return F1;
		}


		float2 voronoihash75( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi75( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mg = 0;
			for ( int j = -2; j <= 2; j++ )
			{
				for ( int i = -2; i <= 2; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash75( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
					float d = 0.707 * sqrt(dot( r, r ));
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			
			 		}
			 	}
			}
			return F1;
		}


		float2 voronoihash76( float2 p )
		{
			
			p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
			return frac( sin( p ) *43758.5453);
		}


		float voronoi76( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
		{
			float2 n = floor( v );
			float2 f = frac( v );
			float F1 = 8.0;
			float F2 = 8.0; float2 mg = 0;
			for ( int j = -2; j <= 2; j++ )
			{
				for ( int i = -2; i <= 2; i++ )
			 	{
			 		float2 g = float2( i, j );
			 		float2 o = voronoihash76( n + g );
					o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
					float d = 0.707 * sqrt(dot( r, r ));
			 		if( d<F1 ) {
			 			F2 = F1;
			 			F1 = d; mg = g; mr = r; id = o;
			 		} else if( d<F2 ) {
			 			F2 = d;
			
			 		}
			 	}
			}
			return F1;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float mulTime153 = _Time.y * _VoronoiSpeed;
			float time47 = mulTime153;
			float2 voronoiSmoothId47 = 0;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult19 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 noiseUv124 = ( appendResult19 * _Scale );
			float mulTime16 = _Time.y * _BigNoiseSpeed;
			float3 appendResult21 = (float3(noiseUv124 , mulTime16));
			float simplePerlin3D5 = snoise( ( _BigNoiseScale * appendResult21 ) );
			float noiseBig130 = ( simplePerlin3D5 * _BigNoiseIntensity );
			float mulTime146 = _Time.y * _SmallNoiseSpeed;
			float3 appendResult132 = (float3(noiseUv124 , mulTime146));
			float simplePerlin3D136 = snoise( ( _SmallNoiseScale * appendResult132 ) );
			float noiseSmall138 = ( simplePerlin3D136 * _SmallNoiseIntensity );
			float2 coords47 = ( ( noiseUv124 + ( _BigNoiseEnable * noiseBig130 ) + ( _SmallNoiseEnable * noiseSmall138 ) ) + ( float2( -1,-1 ) * _EdgeWidth ) ) * 1.0;
			float2 id47 = 0;
			float2 uv47 = 0;
			float voroi47 = voronoi47( coords47, time47, id47, uv47, 0, voronoiSmoothId47 );
			float time74 = mulTime153;
			float2 voronoiSmoothId74 = 0;
			float2 coords74 = ( ( noiseUv124 + ( _BigNoiseEnable * noiseBig130 ) + ( _SmallNoiseEnable * noiseSmall138 ) ) + ( float2( 1,1 ) * _EdgeWidth ) ) * 1.0;
			float2 id74 = 0;
			float2 uv74 = 0;
			float voroi74 = voronoi74( coords74, time74, id74, uv74, 0, voronoiSmoothId74 );
			float time75 = mulTime153;
			float2 voronoiSmoothId75 = 0;
			float2 coords75 = ( ( noiseUv124 + ( _BigNoiseEnable * noiseBig130 ) + ( _SmallNoiseEnable * noiseSmall138 ) ) + ( float2( -1,1 ) * _EdgeWidth ) ) * 1.0;
			float2 id75 = 0;
			float2 uv75 = 0;
			float voroi75 = voronoi75( coords75, time75, id75, uv75, 0, voronoiSmoothId75 );
			float time76 = mulTime153;
			float2 voronoiSmoothId76 = 0;
			float2 coords76 = ( ( noiseUv124 + ( _BigNoiseEnable * noiseBig130 ) + ( _SmallNoiseEnable * noiseSmall138 ) ) + ( float2( 1,-1 ) * _EdgeWidth ) ) * 1.0;
			float2 id76 = 0;
			float2 uv76 = 0;
			float voroi76 = voronoi76( coords76, time76, id76, uv76, 0, voronoiSmoothId76 );
			float temp_output_106_0 = ( sqrt( ( pow( ( id47 - id74 ) , 2.0 ) + pow( ( id75 - id76 ) , 2.0 ) ) ).x > float2( 0,0 ) ? 1.0 : 0.0 );
			float3 temp_cast_1 = (temp_output_106_0).xxx;
			c.rgb = temp_cast_1;
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
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19102
Node;AmplifyShaderEditor.DynamicAppendNode;4;-586.7217,-259.3236;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;6;-273.9831,-144.9994;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;3;-861.9235,-312.2964;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;9;-540.1882,-75.40182;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;2;-347.2889,-426.3164;Inherit;True;Property;_MainTex;Main Tex;0;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;1;-14.53361,-269.0532;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;10;-904.056,44.07418;Inherit;False;Property;_Intensity;Intensity;2;0;Create;True;0;0;0;False;0;False;0.02;0.1;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;24;489.4001,114.9821;Inherit;False;Screen;True;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;39;209.7944,343.0511;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-223.2384,165.7526;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-167.564,388.5681;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;38;-498.5334,621.0646;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-148.6739,592.4406;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCCompareWithRange;42;-519.1085,374.1165;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;-0.5;False;3;FLOAT;1;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-916.4282,367.3759;Inherit;False;-1;;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;27;-552.3581,217.2483;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;-0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;19;-4725.839,-1367.421;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldPosInputsNode;18;-4983.913,-1373.75;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;12;-4872.374,-1174.251;Inherit;False;Property;_Scale;Scale;1;0;Create;True;0;0;0;False;0;False;1;10;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-4517.86,-1276.81;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;124;-4319.23,-1274.545;Inherit;False;noiseUv;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;-4872.905,-464.136;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;125;-5136.89,-489.6106;Inherit;False;124;noiseUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;122;-4647.537,-530.8173;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;5;-4456.287,-540.048;Inherit;False;Simplex3D;False;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;120;-4216.204,-510.478;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;132;-4876.477,-59.30064;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;-5140.462,-84.77525;Inherit;False;124;noiseUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-4651.109,-125.982;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;136;-4459.859,-135.2126;Inherit;False;Simplex3D;False;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;-4219.776,-105.6426;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;123;-4981.58,-568.3018;Inherit;False;Property;_BigNoiseScale;Big Noise Scale;7;0;Create;True;0;0;0;False;0;False;2.473072;0;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-4537.021,-380.0489;Inherit;False;Property;_BigNoiseIntensity;Big Noise Intensity;6;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;130;-4016.403,-509.2567;Inherit;False;noiseBig;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;139;-4985.152,-164.9617;Inherit;False;Property;_SmallNoiseScale;Small Noise Scale;11;0;Create;True;0;0;0;False;0;False;2.473072;0;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;140;-4540.593,24.78648;Inherit;False;Property;_SmallNoiseIntensity;Small Noise Intensity;10;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;142;-1297.358,-107.4721;Inherit;False;130;noiseBig;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;143;-1301.047,6.367706;Inherit;False;138;noiseSmall;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-1302.411,-196.3389;Inherit;False;124;noiseUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;145;-1021.385,-110.45;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;16;-5139.196,-382.1422;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;146;-5139.517,42.72141;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-5489.675,-375.1464;Inherit;False;Property;_BigNoiseSpeed;Big Noise Speed;8;0;Create;True;0;0;0;False;0;False;0.2;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;147;-5489.996,49.71722;Inherit;False;Property;_SmallNoiseSpeed;Small Noise Speed;12;0;Create;True;0;0;0;False;0;False;0.2;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;138;-4021.47,-104.4213;Inherit;False;noiseSmall;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;68;-5008.057,920.4604;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;69;-5018.173,1031.142;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;-1,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;70;-5019.473,1135.142;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;71;-5019.473,1248.242;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-5216.523,957.0212;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;86;-5214.652,1051.627;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;-5218.652,1141.626;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-5216.652,1240.627;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;81;-5455.356,894.6422;Inherit;False;Constant;_Vector0;Vector 0;4;0;Create;True;0;0;0;False;0;False;-1,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;82;-5449.974,1021.668;Inherit;False;Constant;_Vector1;Vector 1;4;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;83;-5444.052,1144.388;Inherit;False;Constant;_Vector2;Vector 2;4;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;84;-5448.823,1273.568;Inherit;False;Constant;_Vector3;Vector 3;4;0;Create;True;0;0;0;False;0;False;1,-1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.VoronoiNode;77;-4691.467,720.3652;Inherit;False;1;1;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.RangedFloatNode;78;-5567.328,1438.427;Inherit;False;Property;_EdgeWidth;Edge Width;3;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;47;-4745.276,887.6559;Inherit;False;1;1;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.VoronoiNode;74;-4746.612,1013.308;Inherit;False;1;1;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.VoronoiNode;75;-4746.514,1137.843;Inherit;False;1;1;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.VoronoiNode;76;-4747.85,1265.772;Inherit;False;1;1;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0.1;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;98;-4519.069,945.6641;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;108;-4361.839,946.1227;Inherit;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;103;-4154.454,1051.41;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SqrtOpNode;110;-4021.841,1052.122;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;99;-4522.219,1205.079;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PowerNode;109;-4359.603,1204.792;Inherit;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;2;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-3640.176,1275.098;Inherit;False;vn;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-3445.446,845.2823;Float;False;True;-1;6;ASEMaterialInspector;0;0;CustomLighting;Maki/Planar Reflection Water;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;0;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;-5958.306,768.4359;Inherit;False;130;noiseBig;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;149;-5756.723,718.1903;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;126;-5783.36,570.5689;Inherit;False;124;noiseUv;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;115;-5457.334,734.458;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;151;-5958.839,965.4599;Inherit;False;138;noiseSmall;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;148;-5980.541,679.8727;Inherit;False;Property;_BigNoiseEnable;Big Noise Enable;5;1;[Toggle];Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;150;-5981.074,876.8969;Inherit;False;Property;_SmallNoiseEnable;Small Noise Enable;9;1;[Toggle];Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;152;-5745.55,901.3907;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;73;-5137.138,764.435;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;72;-4938.37,857.2601;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;153;-5187.871,632.5195;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;154;-5549.871,530.5195;Inherit;False;Property;_VoronoiSpeed;Voronoi Speed;4;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;106;-3874.301,1045.091;Inherit;False;2;4;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
WireConnection;4;0;3;1
WireConnection;4;1;3;2
WireConnection;6;0;4;0
WireConnection;9;0;145;0
WireConnection;9;1;10;0
WireConnection;1;0;2;0
WireConnection;1;1;6;0
WireConnection;24;0;1;0
WireConnection;24;1;39;0
WireConnection;39;0;30;0
WireConnection;39;1;46;0
WireConnection;39;2;41;0
WireConnection;30;0;27;0
WireConnection;46;0;42;0
WireConnection;38;0;44;0
WireConnection;41;0;38;0
WireConnection;42;0;44;0
WireConnection;27;0;44;0
WireConnection;19;0;18;1
WireConnection;19;1;18;3
WireConnection;11;0;19;0
WireConnection;11;1;12;0
WireConnection;124;0;11;0
WireConnection;21;0;125;0
WireConnection;21;2;16;0
WireConnection;122;0;123;0
WireConnection;122;1;21;0
WireConnection;5;0;122;0
WireConnection;120;0;5;0
WireConnection;120;1;121;0
WireConnection;132;0;133;0
WireConnection;132;2;146;0
WireConnection;135;0;139;0
WireConnection;135;1;132;0
WireConnection;136;0;135;0
WireConnection;137;0;136;0
WireConnection;137;1;140;0
WireConnection;130;0;120;0
WireConnection;145;0;144;0
WireConnection;145;1;142;0
WireConnection;145;2;143;0
WireConnection;16;0;17;0
WireConnection;146;0;147;0
WireConnection;138;0;137;0
WireConnection;68;0;73;0
WireConnection;68;1;79;0
WireConnection;69;0;73;0
WireConnection;69;1;86;0
WireConnection;70;0;73;0
WireConnection;70;1;87;0
WireConnection;71;0;73;0
WireConnection;71;1;88;0
WireConnection;79;0;81;0
WireConnection;79;1;78;0
WireConnection;86;0;82;0
WireConnection;86;1;78;0
WireConnection;87;0;83;0
WireConnection;87;1;78;0
WireConnection;88;0;84;0
WireConnection;88;1;78;0
WireConnection;77;0;73;0
WireConnection;77;1;72;0
WireConnection;47;0;68;0
WireConnection;47;1;72;0
WireConnection;74;0;69;0
WireConnection;74;1;72;0
WireConnection;75;0;70;0
WireConnection;75;1;72;0
WireConnection;76;0;71;0
WireConnection;76;1;72;0
WireConnection;98;0;47;1
WireConnection;98;1;74;1
WireConnection;108;0;98;0
WireConnection;103;0;108;0
WireConnection;103;1;109;0
WireConnection;110;0;103;0
WireConnection;99;0;75;1
WireConnection;99;1;76;1
WireConnection;109;0;99;0
WireConnection;111;0;106;0
WireConnection;0;13;106;0
WireConnection;149;0;148;0
WireConnection;149;1;131;0
WireConnection;115;0;126;0
WireConnection;115;1;149;0
WireConnection;115;2;152;0
WireConnection;152;0;150;0
WireConnection;152;1;151;0
WireConnection;73;0;115;0
WireConnection;72;0;153;0
WireConnection;153;0;154;0
WireConnection;106;0;110;0
ASEEND*/
//CHKSM=CA7A52D2578DF96CD408EAC147B85D727D2094D9