Shader "Maki/Coffee Break" {

Properties {

}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off

Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    
    #include "UnityCG.cginc"

    struct appdata {
        float4 vertex : POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f {
        float4 pos : SV_POSITION;
        float3 dir : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    sampler2D _MainTex;
    float4 _MainTex_ST;

    v2f vert(appdata v) {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        o.pos = UnityObjectToClipPos(v.vertex);
        o.dir = normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
        return o;
    }

// https://github.com/nobnak/HLSLNoise

// Cellular noise ("Worley noise") in 3D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.

// fmod is: x - y * trunc(x/y)
#define mod(x, y) (x - y * floor(x / y))

float4 permute(float4 x) {
  return mod((34.0 * x + 1.0) * x, 289.0);
}

// Cellular noise, returning F1 and F2 in a float2.
// Speeded up by using 2x2x2 search window instead of 3x3x3,
// at the expense of some pattern artifacts.
// F2 is often wrong and has sharp discontinuities.
// If you need a good F2, use the slower 3x3x3 version.
float2 cellular2x2x2(float3 P) {
    #define K 0.142857142857 // 1/7
	#define Ko 0.428571428571 // 1/2-K/2
	#define K2 0.020408163265306 // 1/(7*7)
	#define Kz 0.166666666667 // 1/6
	#define Kzo 0.416666666667 // 1/2-1/6*2
	#define jitter 0.8 // smaller jitter gives less errors in F2
    float3 Pi = mod(floor(P), 289.0);
    float3 Pf = frac(P);
    float4 Pfx = Pf.x + float4(0.0, -1.0, 0.0, -1.0);
    float4 Pfy = Pf.y + float4(0.0, 0.0, -1.0, -1.0);
    float4 p = permute(Pi.x + float4(0.0, 1.0, 0.0, 1.0));
    p = permute(p + Pi.y + float4(0.0, 0.0, 1.0, 1.0));
    float4 p1 = permute(p + Pi.z); // z+0
    float4 p2 = permute(p + Pi.z + 1.0); // z+1
    float4 ox1 = frac(p1*K) - Ko;
    float4 oy1 = mod(floor(p1*K), 7.0)*K - Ko;
    float4 oz1 = floor(p1*K2)*Kz - Kzo; // p1 < 289 guaranteed
    float4 ox2 = frac(p2*K) - Ko;
    float4 oy2 = mod(floor(p2*K), 7.0)*K - Ko;
    float4 oz2 = floor(p2*K2)*Kz - Kzo;
    float4 dx1 = Pfx + jitter*ox1;
    float4 dy1 = Pfy + jitter*oy1;
    float4 dz1 = Pf.z + jitter*oz1;
    float4 dx2 = Pfx + jitter*ox2;
    float4 dy2 = Pfy + jitter*oy2;
    float4 dz2 = Pf.z - 1.0 + jitter*oz2;
    float4 d1 = dx1 * dx1 + dy1 * dy1 + dz1 * dz1; // z+0
    float4 d2 = dx2 * dx2 + dy2 * dy2 + dz2 * dz2; // z+1

    // Sort out the two smallest distances (F1, F2)
    // Cheat and sort out only F1
    // > code removed by spirv

    // Do it right and sort out both F1 and F2

    float4 d = min(d1,d2); // F1 is now in d
    d2 = max(d1,d2); // Make sure we keep all candidates for F2
    d.xy = (d.x < d.y) ? d.xy : d.yx; // Swap smallest to d.x
    d.xz = (d.x < d.z) ? d.xz : d.zx;
    d.xw = (d.x < d.w) ? d.xw : d.wx; // F1 is now in d.x
    d.yzw = min(d.yzw, d2.yzw); // F2 now not in d2.yzw
    d.y = min(d.y, d.z); // nor in d.z
	d.y = min(d.y, d.w); // nor in d.w
	d.y = min(d.y, d2.x); // F2 is now in d.y
	return sqrt(d.xy); // F1 and F2
}

// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

float rand(float n){return frac(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
    float fc = frac(p);
	return lerp(rand(fl), rand(fl + 1.0), fc);
}

// Copyright (c) 2020 Maki. All rights reserved.

// precision mediump float;

#define colorBg float3(1.0, 47.0, 113.0)   / 255.0
#define colorBlue float3(8.0, 48.0, 170.0) / 255.0
#define colorGreen float3(2.0, 87.0, 53.0) / 255.0

// t/20, t, t*2, t*3
#define iGlobalTime _Time.y * .5

float2 wobbly(float2 uv, float speed, float repetition, float amount, float offset) {
    return float2(
        uv.x,
        uv.y + sin(uv.y * repetition + (iGlobalTime+offset) * speed) / amount
    );
}

float bubbles(float2 uv, float offset, float direction) {
	float zoom = 6.0;

    uv*=zoom;

    uv = wobbly(uv, 0.5, 0.18*zoom, 0.2*zoom, offset);
    uv.x -= iGlobalTime * 0.3 * direction;
    uv.y -= iGlobalTime * 1.0;


	float2 F = cellular2x2x2(
		float3(
			uv*2,
			(iGlobalTime + offset) * 0.2
		)
	);

	float maxSs = 0.33;
	float minSs = maxSs - 0.0001;

	float _size = 0.0;
	float ringVisibleWidth = 0.02;
	float ringInvisibleWidth = 0.045;

	float final = 1.0 - smoothstep(minSs, maxSs, F.x);

	_size += ringVisibleWidth;
	final -= 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);
	
	for (int i=0; i<3; i++) {
		_size += ringInvisibleWidth;
		final += 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);

		_size += ringVisibleWidth;
		final -= 1.0 - smoothstep(minSs-_size, maxSs-_size, F.x);
	}

	return clamp(final, 0.0, 1.0);
}

float2 pixelateUV(float2 uv, float amount) {
	return floor(uv * amount) / amount;
}

#define PI 3.14159265359
#define TAU 6.28318530718
      
float2 getUVFromDir(float3 dir) {
    float r = length(dir);
    float theta = acos(-dir.y / r);
    float phi = atan2(dir.x, -dir.z);

    return float2(
        phi/TAU,
        1.0 - theta/PI
    );
}

fixed4 frag(v2f i) : SV_Target {
    float2 uv = getUVFromDir(i.dir) * -7.0 * 0.5;
    uv = pixelateUV(uv, 200.0 * 2);

    float blueBubbles = bubbles(uv.xy, 11512.11, 1.0);
    float blueOpacity = smoothstep(0.2, 0.6, noise((iGlobalTime + 11512.11) * 1.0));
	float blueCombined = clamp(blueBubbles * blueOpacity, 0.0, 1.0);

    float greenBubbles = bubbles(uv, 82351.93, -1.0);
	float greenOpacity = smoothstep(0.2, 0.6, noise((iGlobalTime + 82351.93) * 1.0));
	float greenCombined = clamp(greenBubbles * greenOpacity, 0.0, 1.0);

    fixed3 color = lerp(
		lerp(
			colorBg, // a
			colorBlue, // b
			blueCombined // alpha
		), // a
		colorGreen, // b
		greenCombined // alpha
	);

    return fixed4(pow(color, 2.2), 1.0);
}

ENDCG
}
}
}
