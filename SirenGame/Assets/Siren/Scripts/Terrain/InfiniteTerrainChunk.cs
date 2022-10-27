using System;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

namespace Siren.Scripts.Terrain
{
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(MeshCollider))]
    public class InfiniteTerrainChunk : MonoBehaviour
    {
        public InfiniteTerrain infiniteTerrain;
        public Vector2Int chunkPosition;

        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private MeshCollider _meshCollider;

        private (Vector3[], int[]) _meshData;
        private (Vector3[], int[]) _physicsMeshData;

        public bool allMeshDataGenerated;
        public bool allMeshDataApplied;

        private void Awake()
        {
            _meshFilter = GetComponent<MeshFilter>();
            _meshRenderer = GetComponent<MeshRenderer>();
            _meshCollider = GetComponent<MeshCollider>();
        }

        private float GetNoise(float x, float z)
        {
            x += chunkPosition.x * infiniteTerrain.chunkSize;
            z += chunkPosition.y * infiniteTerrain.chunkSize;

            return (
                Mathf.PerlinNoise(
                    x * infiniteTerrain.noiseSize + 1290f,
                    z * infiniteTerrain.noiseSize + 1092f
                ) * 2 - 1
            ) * infiniteTerrain.noiseHeight;
        }

        private (Vector3[], int[]) GenerateMeshData(int chunkResolution)
        {
            Profiler.BeginSample("Chunk GenerateMeshData");

            var chunkSize = infiniteTerrain.chunkSize;

            var vertices = new Vector3[(chunkResolution + 1) * (chunkResolution + 1)];

            var squareSize = chunkSize / (float) chunkResolution;

            var i = 0;
            for (var z = 0; z <= chunkResolution; z++)
            {
                for (var x = 0; x <= chunkResolution; x++)
                {
                    var y = GetNoise(x * squareSize, z * squareSize);
                    vertices[i] = new Vector3(x * squareSize, y, z * squareSize);
                    i++;
                }
            }

            var triangles = new int[chunkResolution * chunkResolution * 6];

            var vert = 0;
            var tris = 0;

            for (var z = 0; z < chunkResolution; z++)
            {
                for (var x = 0; x < chunkResolution; x++)
                {
                    triangles[tris + 0] = vert + 0;
                    triangles[tris + 1] = vert + chunkResolution + 1;
                    triangles[tris + 2] = vert + 1;
                    triangles[tris + 3] = vert + 1;
                    triangles[tris + 4] = vert + chunkResolution + 1;
                    triangles[tris + 5] = vert + chunkResolution + 2;

                    vert++;
                    tris += 6;
                }

                vert++;
            }

            Profiler.EndSample();

            return (vertices, triangles);
        }

        public void GenerateAllMeshData()
        {
            Profiler.BeginSample("Chunk GenerateAllMeshData");

            _meshData = GenerateMeshData(infiniteTerrain.chunkResolution);
            _physicsMeshData = GenerateMeshData(32);

            allMeshDataGenerated = true;

            Profiler.EndSample();
        }

        public void UpdateGameObjectMesh()
        {
            Profiler.BeginSample("Chunk UpdateGameObjectMesh");

            if (!allMeshDataGenerated) return;

            _meshRenderer.material = infiniteTerrain.terrainMaterial;

            var mesh = new Mesh
            {
                name = gameObject.name,
                vertices = _meshData.Item1,
                triangles = _meshData.Item2,
                indexFormat = IndexFormat.UInt16
            };
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            // mesh.Optimize();

            _meshFilter.sharedMesh = mesh;

            var physicsMesh = new Mesh
            {
                name = "Physics " + gameObject.name,
                vertices = _physicsMeshData.Item1,
                triangles = _physicsMeshData.Item2,
                indexFormat = IndexFormat.UInt16
            };
            physicsMesh.RecalculateNormals();
            physicsMesh.RecalculateBounds();
            // physicsMesh.Optimize();

            _meshCollider.cookingOptions = MeshColliderCookingOptions.None;
            _meshCollider.sharedMesh = physicsMesh;

            allMeshDataApplied = true;

            Profiler.EndSample();
        }
    }
}