using UnityEngine;

namespace Siren.Scripts.Terrain
{
    public class NoiseGenerator : MonoBehaviour
    {

    
        [Range(0, 512)] public int noiseFalloff = 128;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeightMax = 10;
        [Range(0.1f, 100f)] public float noiseHeightMin = 10;
        
    
    

    }
}
