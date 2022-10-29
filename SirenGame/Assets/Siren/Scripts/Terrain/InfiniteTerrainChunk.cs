using System;
using System.Threading;
using System.Threading.Tasks;
using Siren.Scripts.UI;
using Siren.Scripts.Utils;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.Serialization;

namespace Siren.Scripts.Terrain
{
    public enum ChunkStatus
    {
        NeedMeshGen,
        GotMeshGen,
        NeedPhysicsBake,
        GotPhysicsBake,
        Done
    }

    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [RequireComponent(typeof(MeshCollider))]
    public class InfiniteTerrainChunk : MonoBehaviour
    {
        public InfiniteTerrain infiniteTerrain;
        public Vector2Int chunkPosition;

        private (Vector3[], int[], Vector2[], Vector3[]) _meshData;
        private Mesh _mesh;

        private int _meshInstanceId;

        public bool doingExternalThreadWork;
        public ChunkStatus status = ChunkStatus.NeedMeshGen;

        private CancellationTokenSource _cts = new();

        // private Bounds _bounds;
        //
        // private void OnDrawGizmosSelected()
        // {
        //     GizmoUtils.DrawBounds(_bounds);
        // }

        private float GetNoise(float x, float z, float noiseSize, float noiseHeight)
        {
            x += chunkPosition.x * infiniteTerrain.chunkSize;
            z += chunkPosition.y * infiniteTerrain.chunkSize;

            return (
                Mathf.PerlinNoise(
                    x * noiseSize + 1290f,
                    z * noiseSize + 1092f
                ) * 2 - 1
            ) * noiseHeight;
        }

        private (Vector3[], int[], Vector2[], Vector3[]) GenerateMeshData(int chunkResolution)
        {
            Profiler.BeginSample("Chunk GenerateMeshData");

            var chunkSize = infiniteTerrain.chunkSize;
            var halfAChunk = chunkSize / 2;

            var verticesLength = (chunkResolution + 1) * (chunkResolution + 1);
            var vertices = new Vector3[verticesLength];
            var uv = new Vector2[verticesLength];
            var normals = new Vector3[verticesLength];

            var squareSize = chunkSize / (float) chunkResolution;

            var chunkWorldPosition = new Vector3(
                (float) chunkPosition.x * infiniteTerrain.chunkSize,
                0,
                (float) chunkPosition.y * infiniteTerrain.chunkSize
            );

            var bounds = new Bounds(
                chunkWorldPosition,
                new Vector3(chunkSize, 99999, chunkSize)
            );

            var areaModifiers = infiniteTerrain.GetAreaModifiersInBounds(bounds);

            var i = 0;
            for (var z = 0; z <= chunkResolution; z++)
            {
                for (var x = 0; x <= chunkResolution; x++)
                {
                    var worldPosition = chunkWorldPosition + new Vector3(
                        x * squareSize - halfAChunk,
                        0,
                        z * squareSize - halfAChunk
                    );

                    Vector3 GetPos(int queryX, int queryZ)
                    {
                        var y = GetNoise(
                            queryX * squareSize,
                            queryZ * squareSize,
                            infiniteTerrain.noiseSize,
                            infiniteTerrain.noiseHeight
                        );

                        if (areaModifiers.Length > 0)
                        {
                            var modifier = areaModifiers[0];

                            var distance = modifier.XZDistanceFrom(worldPosition);
                            var totalRadius = modifier.radius + modifier.falloff;

                            if (distance < totalRadius)
                            {
                                // we're in radius + falloff

                                var modifierY = GetNoise(
                                    queryX * squareSize,
                                    queryZ * squareSize,
                                    modifier.noiseSize,
                                    modifier.noiseHeight
                                );

                                modifierY += modifier.GetPosition().y;

                                if (distance < modifier.radius)
                                {
                                    // in radius
                                    y = modifierY;
                                }
                                else
                                {
                                    // in falloff
                                    var t = Mathf.InverseLerp(modifier.radius, totalRadius, distance);
                                    y = Mathf.Lerp(
                                        modifierY,
                                        y,
                                        EasingFunctions.Ease(t, modifier.easing)
                                    );
                                }
                            }
                        }

                        return new Vector3(
                            queryX * squareSize - halfAChunk,
                            y,
                            queryZ * squareSize - halfAChunk
                        );
                    }

                    var position = GetPos(x, z);
                    vertices[i] = position;

                    uv[i] = new Vector2((float) x / chunkResolution, (float) z / chunkResolution);

                    var n = GetPos(x, z + 1) - position;
                    var e = GetPos(x + 1, z) - position;
                    var w = GetPos(x - 1, z) - position;
                    var s = GetPos(x, z - 1) - position;

                    var normal = (
                        Vector3.Cross(n, e) +
                        Vector3.Cross(e, s) +
                        Vector3.Cross(s, w) +
                        Vector3.Cross(w, n)
                    );
                    
                    normal.Normalize();

                    normals[i] = normal;

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

            return (vertices, triangles, uv, normals);
        }

        private void GenerateAllMeshData()
        {
            Profiler.BeginSample("Chunk GenerateAllMeshData");

            _meshData = GenerateMeshData(infiniteTerrain.chunkResolution);

            Profiler.EndSample();
        }

        private void CreateMeshes()
        {
            Profiler.BeginSample("Chunk CreateMeshes");

            _mesh = new Mesh
            {
                name = gameObject.name,
                vertices = _meshData.Item1,
                triangles = _meshData.Item2,
                uv = _meshData.Item3,
                normals = _meshData.Item4,
                indexFormat = IndexFormat.UInt16
            };
            // _mesh.RecalculateNormals();
            _mesh.RecalculateBounds();
            // _mesh.Optimize();

            _meshInstanceId = _mesh.GetInstanceID();

            Profiler.EndSample();
        }

        private void PhysicsBake()
        {
            Profiler.BeginSample("Chunk PhysicsBake");

            Physics.BakeMesh(_meshInstanceId, false);

            Profiler.EndSample();
        }

        private void PushMeshes()
        {
            Profiler.BeginSample("Chunk PushMeshes");

            GetComponent<MeshRenderer>().material = infiniteTerrain.terrainMaterial;

            GetComponent<MeshFilter>().sharedMesh = _mesh;
            GetComponent<MeshCollider>().sharedMesh = _mesh;

            Profiler.EndSample();
        }

        public void ReloadThreadSafe()
        {
            _cts.Cancel();
            doingExternalThreadWork = false;
            status = ChunkStatus.NeedMeshGen;
        }

        public Task DoExternalThreadWork()
        {
            if (doingExternalThreadWork) return Task.CompletedTask;
            doingExternalThreadWork = true;

            return Task.Run(() =>
            {
                switch (status)
                {
                    case ChunkStatus.NeedMeshGen:
                        GenerateAllMeshData();
                        status = ChunkStatus.GotMeshGen;
                        break;
                    case ChunkStatus.NeedPhysicsBake:
                        PhysicsBake();
                        status = ChunkStatus.GotPhysicsBake;
                        break;
                }

                doingExternalThreadWork = false;
            });
        }

        public void DoMainThreadWork()
        {
            switch (status)
            {
                case ChunkStatus.GotMeshGen:
                    CreateMeshes();
                    status = ChunkStatus.NeedPhysicsBake;
                    break;
                case ChunkStatus.GotPhysicsBake:
                    PushMeshes();
                    status = ChunkStatus.Done;
                    break;
            }
        }
    }
}