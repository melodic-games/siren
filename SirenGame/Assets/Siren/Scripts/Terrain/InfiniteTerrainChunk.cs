﻿using System;
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

        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private MeshCollider _meshCollider;

        private (Vector3[], int[]) _meshData;
        private Mesh _mesh;

        private (Vector3[], int[]) _physicsMeshData;
        private Mesh _physicsMesh;
        private int _physicsMeshInstanceId;

        public ChunkStatus status = ChunkStatus.NeedMeshGen;

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

        private void GenerateAllMeshData()
        {
            Profiler.BeginSample("Chunk GenerateAllMeshData");

            _meshData = GenerateMeshData(infiniteTerrain.chunkResolution);
            _physicsMeshData = GenerateMeshData(infiniteTerrain.chunkResolution);

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
                indexFormat = IndexFormat.UInt16
            };
            _mesh.RecalculateNormals();
            _mesh.RecalculateBounds();
            // _mesh.Optimize();


            _physicsMesh = new Mesh
            {
                name = "Physics " + gameObject.name,
                vertices = _physicsMeshData.Item1,
                triangles = _physicsMeshData.Item2,
                indexFormat = IndexFormat.UInt16
            };
            _physicsMesh.RecalculateNormals();
            _physicsMesh.RecalculateBounds();
            // _physicsMesh.Optimize();

            _physicsMeshInstanceId = _physicsMesh.GetInstanceID();

            Profiler.EndSample();
        }

        private void PhysicsBake()
        {
            Profiler.BeginSample("Chunk PhysicsBake");

            Physics.BakeMesh(_physicsMeshInstanceId, false);

            Profiler.EndSample();
        }

        private void PushMeshes()
        {
            Profiler.BeginSample("Chunk PushMeshes");

            _meshRenderer.material = infiniteTerrain.terrainMaterial;

            _meshFilter.sharedMesh = _mesh;
            _meshCollider.sharedMesh = _physicsMesh;

            Profiler.EndSample();
        }

        public void DoExternalThreadWork()
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