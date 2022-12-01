using UnityEngine;

namespace Siren.Scripts.Color_Palettes
{
    [CreateAssetMenu(menuName = "Siren/World Color Palette", order = 0, fileName = "New World Color Palette")]
    public class WorldColorPalette : ScriptableObject
    {
        public Color ambientColor = Color.white;
        public Color shadowColor = Color.black;
    }
}