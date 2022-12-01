using UnityEngine;

namespace Siren.Scripts.Color_Palettes
{
    [ExecuteInEditMode]
    public class WorldColorPaletteController : MonoBehaviour
    {
        public WorldColorPalette worldColorPalette;

        private static readonly int SirenAmbientColor = Shader.PropertyToID("SirenAmbientColor");
        private static readonly int SirenShadowColor = Shader.PropertyToID("SirenShadowColor");

        private void Update()
        {
            if (worldColorPalette == null) return;
            Shader.SetGlobalColor(SirenAmbientColor, worldColorPalette.ambientColor.linear);
            Shader.SetGlobalColor(SirenShadowColor, worldColorPalette.shadowColor.linear);
        }
    }
}