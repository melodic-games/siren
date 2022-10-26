#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.cs.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
#endif

void GetMainLightData_float(out float3 Direction, out float3 Color)
{
#if SHADERGRAPH_PREVIEW
    Direction = float3(0.5, 0.5, 0);
    Color = 1;
#else
    if (_DirectionalLightCount > 0)
    {
        DirectionalLightData mainLight = _DirectionalLightDatas[0];
        Direction = -mainLight.forward.xyz;
        Color = mainLight.color;
    }
#endif
}

#endif