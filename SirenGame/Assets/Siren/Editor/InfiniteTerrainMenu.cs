using UnityEditor;
using UnityEngine;
using Siren.Scripts.Terrain;

namespace Siren.Editor
{
    public static class InfiniteTerrainMenu
    {
        [MenuItem("GameObject/Siren/Infinite Terrain")]
        private static void CreateInfiniteTerrain()
        {
           
            var gameObject = new GameObject(
                "Infinite Terrain",
                typeof(InfiniteTerrain)
            );
        }

        [MenuItem("GameObject/Siren/Infinite Terrain Area Modifier")]
        private static void CreateInfiniteTerrainAreaModifier()
        {
            var gameObject = new GameObject(
                "Infinite Terrain Area Modifier",
                typeof(InfiniteTerrainAreaModifier)
            );
        }
    }
}