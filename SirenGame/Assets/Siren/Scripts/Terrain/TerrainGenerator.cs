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
        public float squareSize = 1f;
        public int terrainSquares = 16;
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
            return Mathf.PerlinNoise(x * 0.1f + 1290f, z * 0.1f + 1092f) * 10f;
        }

        private void GenerateTerrain()
        {
            var terrainGenerator = (TerrainGenerator) target;
            var squareSize = terrainGenerator.squareSize;
            var terrainSquares = terrainGenerator.terrainSquares;

            var terrainOffset =
                new Vector3(terrainSquares * squareSize / 2, 0, terrainSquares * squareSize / 2);

            // var terrainOffset = Vector3.zero;

            var vertices = new Vector3[(terrainSquares + 1) * (terrainSquares + 1)];
            var triangles = new int[terrainSquares * terrainSquares * 6];

            var invSquareSize = 1f / squareSize;

            for (var z = 0; z < terrainSquares + 1; z++)
            {
                for (var x = 0; x < terrainSquares + 1; x++)
                {
                    var i = GetIndex(x, z, terrainSquares + 1);

                    var noise = GetNoise(
                        x * squareSize - terrainOffset.x,
                        z * squareSize - terrainOffset.z
                    ) * invSquareSize;
                    
                    // var noise = 0f;

                    vertices[i] = new Vector3(x, noise, z) * squareSize - terrainOffset;

                    if (x < terrainSquares && z < terrainSquares)
                    {
                        var triI = GetIndex(x, z, terrainSquares);
                        triangles[triI * 6 + 0] = GetIndex(x + 0, z + 0, terrainSquares + 1);
                        triangles[triI * 6 + 1] = GetIndex(x + 0, z + 1, terrainSquares + 1);
                        triangles[triI * 6 + 2] = GetIndex(x + 1, z + 1, terrainSquares + 1);
                        triangles[triI * 6 + 3] = GetIndex(x + 1, z + 1, terrainSquares + 1);
                        triangles[triI * 6 + 4] = GetIndex(x + 1, z + 0, terrainSquares + 1);
                        triangles[triI * 6 + 5] = GetIndex(x + 0, z + 0, terrainSquares + 1);
                    }
                }
            }

            var mesh = new Mesh
            {
                name = "Siren Generated Terrain",
                indexFormat = IndexFormat.UInt32,
                vertices = vertices,
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

            terrainGenerator.squareSize =
                EditorGUILayout.Slider("Square size", terrainGenerator.squareSize, 0f, 1f);

            terrainGenerator.terrainSquares =
                EditorGUILayout.IntSlider("Terrain squares", terrainGenerator.terrainSquares, 0, 2048);

            if (GUILayout.Button("Generate terrain"))
            {
                GenerateTerrain();
            }
        }
    }
#endif
}