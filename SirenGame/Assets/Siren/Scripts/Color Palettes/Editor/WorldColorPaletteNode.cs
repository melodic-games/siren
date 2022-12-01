using System;
using AmplifyShaderEditor;
using UnityEngine;

namespace AmplifyShaderEditor
{
    [Serializable]
    [NodeAttributes("Siren World Color Palette", "Siren", "")]
    public class SirenColorsNode : ParentNode
    {
        protected override void CommonInit(int uniqueId)
        {
            base.CommonInit(uniqueId);
            AddOutputPort(WirePortDataType.FLOAT3, "AmbientColor");
            AddOutputPort(WirePortDataType.FLOAT3, "ShadowColor");
        }

        public override string GenerateShaderForOutput(
            int outputId, ref MasterNodeDataCollector dataCollector, bool ignoreLocalVar
        )
        {
            var name = "Siren" + m_outputPortsDict[outputId].Name;
            dataCollector.AddToUniforms(outputId, "float3", name);
            return name;
        }
    }
}