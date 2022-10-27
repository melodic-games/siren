using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Siren.Scripts.Terrain
{
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(MeshCollider))]
    public class TerrainGenerator : MonoBehaviour
    {
        public int terrainResolution = 128;
        public float terrainSize = 100f;
        public float noiseSize = 1f;
        public float noiseHeight = 1f;
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(TerrainGenerator))]
    public class TerrainGeneratorEditor : Editor
    {
        private static int GetIndex(int x, int z, int width)
        {
            return z * width + x;
        }

        private float GetNoise(float x, float z)
        {
            var terrainGenerator = (TerrainGenerator) target;

            return Mathf.PerlinNoise(
                x * (1 / terrainGenerator.noiseSize) + 1290f,
                z * (1 / terrainGenerator.noiseSize) + 1092f
            ) * terrainGenerator.noiseHeight;
        }

        private void GenerateTerrain()
        {
            var terrainGenerator = (TerrainGenerator) target;
            var terrainResolution = terrainGenerator.terrainResolution;
            var terrainSize = terrainGenerator.terrainSize;
            var squareSize = terrainSize / terrainResolution;

            var terrainOffset =
                new Vector3(terrainSize * 0.5f, 0, terrainSize * 0.5f);

            // var terrainOffset = Vector3.zero;

            var vertices = new Vector3[(terrainResolution + 1) * (terrainResolution + 1)];
            var uv = new Vector2[(terrainResolution + 1) * (terrainResolution + 1)];

            var triangles = new int[terrainResolution * terrainResolution * 6];

            for (var z = 0; z < terrainResolution + 1; z++)
            {
                for (var x = 0; x < terrainResolution + 1; x++)
                {
                    var i = GetIndex(x, z, terrainResolution + 1);

                    var noise = GetNoise(
                        x * squareSize - terrainOffset.x,
                        z * squareSize - terrainOffset.z
                    );
                    
                    vertices[i] = new Vector3(x * squareSize, noise, z * squareSize) - terrainOffset;
                    uv[i] = new Vector2((float) x / terrainResolution, (float) z / terrainResolution);

                    if (x < terrainResolution && z < terrainResolution)
                    {
                        var triI = GetIndex(x, z, terrainResolution);
                        triangles[triI * 6 + 0] = GetIndex(x + 0, z + 0, terrainResolution + 1);
                        triangles[triI * 6 + 1] = GetIndex(x + 0, z + 1, terrainResolution + 1);
                        triangles[triI * 6 + 2] = GetIndex(x + 1, z + 1, terrainResolution + 1);
                        triangles[triI * 6 + 3] = GetIndex(x + 1, z + 1, terrainResolution + 1);
                        triangles[triI * 6 + 4] = GetIndex(x + 1, z + 0, terrainResolution + 1);
                        triangles[triI * 6 + 5] = GetIndex(x + 0, z + 0, terrainResolution + 1);
                    }
                }
            }

            var mesh = new Mesh
            {
                name = "Siren Generated Terrain",
                indexFormat = IndexFormat.UInt32,
                vertices = vertices,
                uv = uv,
                triangles = triangles,
            };

            mesh.RecalculateNormals();

            terrainGenerator.GetComponent<MeshFilter>().sharedMesh = mesh;
            terrainGenerator.GetComponent<MeshCollider>().sharedMesh = mesh;
        }

        public override void OnInspectorGUI()
        {
            // DrawDefaultInspector();

            EditorGUILayout.Separator();

            var terrainGenerator = (TerrainGenerator) target;

            terrainGenerator.terrainResolution =
                EditorGUILayout.IntSlider("Terrain Resolution", terrainGenerator.terrainResolution, 128, 1024);

            terrainGenerator.terrainSize =
                EditorGUILayout.Slider("Terrain Size", terrainGenerator.terrainSize, 100f, 1000f);

            terrainGenerator.noiseSize =
                EditorGUILayout.Slider("Noise Size", terrainGenerator.noiseSize, 1f, 100f);

            terrainGenerator.noiseHeight =
                EditorGUILayout.Slider("Noise Height", terrainGenerator.noiseHeight, 0.1f, 100f);


            if (GUILayout.Button("Generate terrain"))
            {
                GenerateTerrain();
            }
        }
    }
#endif
}