using System;
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

        private (Vector3[], int[], Vector2[]) _meshData;
        private Mesh _mesh;

        private int _meshInstanceId;

        public bool doingExternalThreadWork;
        public ChunkStatus status = ChunkStatus.NeedMeshGen;

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

        private (Vector3[], int[], Vector2[]) GenerateMeshData(int chunkResolution)
        {
            Profiler.BeginSample("Chunk GenerateMeshData");

            var chunkSize = infiniteTerrain.chunkSize;
            var halfAChunk = chunkSize / 2;

            var vertices = new Vector3[(chunkResolution + 1) * (chunkResolution + 1)];
            var uv = new Vector2[(chunkResolution + 1) * (chunkResolution + 1)];

            var squareSize = chunkSize / (float) chunkResolution;

            var chunkWorldPosition = new Vector3(
                (float) chunkPosition.x * infiniteTerrain.chunkSize,
                0,
                (float) chunkPosition.y * infiniteTerrain.chunkSize
            );

            var bounds = new Bounds(
                chunkWorldPosition,
                new Vector3(chunkSize, 999, chunkSize)
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

                    var y = GetNoise(
                        x * squareSize,
                        z * squareSize,
                        infiniteTerrain.noiseSize,
                        infiniteTerrain.noiseHeight
                    );


                    if (areaModifiers.Length > 0)
                    {
                        var modifier = areaModifiers[0];

                        var distance = modifier.DistanceFrom(worldPosition);
                        var totalRadius = modifier.radius + modifier.falloff;

                        if (distance < totalRadius)
                        {
                            // we're in radius + falloff

                            var modifierY = GetNoise(
                                x * squareSize,
                                z * squareSize,
                                modifier.noiseSize,
                                modifier.noiseHeight
                            );

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
                                    EasingFunctions.Ease(t, EasingFunctions.Easing.InOutSine)
                                );
                            }
                        }
                    }

                    vertices[i] = new Vector3(
                        x * squareSize - halfAChunk,
                        y,
                        z * squareSize - halfAChunk
                    );

                    uv[i] = new Vector2((float) x / chunkResolution, (float) z / chunkResolution);

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

            return (vertices, triangles, uv);
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
                indexFormat = IndexFormat.UInt16
            };
            _mesh.RecalculateNormals();
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

        public void DoExternalThreadWork()
        {
            if (doingExternalThreadWork) return;
            doingExternalThreadWork = true;

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