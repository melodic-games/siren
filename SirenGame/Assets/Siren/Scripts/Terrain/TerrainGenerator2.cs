using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

namespace Siren.Scripts.Terrain
{
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(MeshCollider))]
    [ExecuteInEditMode]
    public class TerrainGenerator2 : MonoBehaviour
    {
        private Mesh _mesh;
        
        private Vector3[] _vertices;
        private int[] _triangles;
        private string _settingsPrevious = "";
        private MeshCollider _meshCollider;

        [Range(100f, 5000f)] public int terrainSize = 500;
        [Range(128, 512)] public int terrainResolution = 128;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeight = 10;

        private void Awake()
        {
            _meshCollider = gameObject.GetComponent<MeshCollider>();
            _mesh = new Mesh();
            GetComponent<MeshFilter>().mesh = _mesh;
        }

        private void Update()
        {
            var settings = new[]
            {
                terrainResolution, 
                terrainSize, 
                noiseSize, 
                noiseHeight
            }.Aggregate("", (acc, val) => acc + val);

            if (_settingsPrevious == settings)
                return;

            _settingsPrevious = settings;
            GenerateTerrain();
        }
        
        private static float GetNoise(float x, float z, float size, float height)
        {
            return (Mathf.PerlinNoise(x * size + 1290f, z * size + 1092f) * 2 - 1) * height;
        }

        private void CreateShape()
        {
            _vertices = new Vector3[(terrainResolution + 1) * (terrainResolution + 1)];
            
            var squareSize = terrainSize / (float) terrainResolution;
            var terrainOffset = new Vector3(terrainSize * 0.5f, 0, terrainSize * 0.5f);
            
            for (int i = 0, z = 0; z <= terrainResolution; z++)
            {
                for (var x = 0; x <= terrainResolution; x++)
                {
                    var y = GetNoise(
                        x * squareSize - terrainOffset.x,
                        z * squareSize - terrainOffset.z,
                        noiseSize,
                        noiseHeight
                    );
                    
                    _vertices[i] = new Vector3(x * squareSize, y, z * squareSize) - terrainOffset;
                    i++;
                }
            }

            _triangles = new int[terrainResolution * terrainResolution * 6];
            
            var vert = 0;
            var tris = 0;

            for (var z = 0; z < terrainResolution; z++)
            {
                for (var x = 0; x < terrainResolution; x++)
                {
                    _triangles[tris + 0] = vert + 0;
                    _triangles[tris + 1] = vert + terrainResolution + 1;
                    _triangles[tris + 2] = vert + 1;
                    _triangles[tris + 3] = vert + 1;
                    _triangles[tris + 4] = vert + terrainResolution + 1;
                    _triangles[tris + 5] = vert + terrainResolution + 2;

                    vert++;
                    tris += 6;
                }
                vert++;
            }

        }

        private void GenerateTerrain()
        {
            CreateShape();
            _mesh.Clear();
            _mesh.indexFormat = IndexFormat.UInt32;
            _mesh.vertices = _vertices;
            _mesh.triangles = _triangles;
            
            _mesh.RecalculateNormals();
            
            _mesh.RecalculateBounds();
            _meshCollider.sharedMesh = _mesh;
        }
    }
}
