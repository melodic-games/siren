using System;
using System.Threading;
using System.Threading.Tasks;
using Siren.Scripts.UI;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

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

        private void Start()
        {
            // idk contribute gi should be disabled but we can do this by just setting the game object to static
// #if UNITY_EDITOR
//             GameObjectUtility.SetStaticEditorFlags(gameObject, StaticEditorFlags.ContributeGI);
// #endif
        }

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

            var squareSize = (float) chunkSize / chunkResolution;

            var chunkWorldPosition = new Vector3(
                (float) chunkPosition.x * infiniteTerrain.chunkSize,
                0,
                (float) chunkPosition.y * infiniteTerrain.chunkSize
            );

            // center y pos is at 0 so y size doesnt matter much 
            var bounds = new Bounds(
                chunkWorldPosition,
                new Vector3(chunkSize, 1, chunkSize)
            );

            var areaModifiers = infiniteTerrain.GetAreaModifiersInBoundsOrdered(bounds);

            float GetY(float x, float z)
            {
                var y = GetNoise(
                    x,
                    z,
                    infiniteTerrain.noiseSize,
                    infiniteTerrain.noiseHeight
                );

                if (areaModifiers.Length <= 0) return y;

                var worldPosition = chunkWorldPosition + new Vector3(
                    x,
                    0,
                    z
                );

                foreach (var mod in areaModifiers)
                {
                    var distance = mod.XZDistanceFrom(worldPosition);
                    var totalRadius = mod.radius + mod.falloff;
                    
                    // modifier.blendMode

                    var modifierPosition = mod.GetPosition();

                    var modX = x + mod.noiseOffset.x;
                    var modZ = z + mod.noiseOffset.y;
                    if (mod.noiseShouldFollow)
                    {
                        modX -= modifierPosition.x;
                        modZ -= modifierPosition.z;
                    }
                    
                    var modY = GetNoise(
                        modX,
                        modZ,
                        mod.noiseSize,
                        mod.noiseHeight
                    );

                    modY += modifierPosition.y;

                    if (distance < mod.radius)
                    {
                        // in radius
                        y = modY;
                    }
                    else
                    {
                        // in falloff and bounding box
                        var t = Mathf.InverseLerp(mod.radius, totalRadius, distance);
                        y = Mathf.Lerp(
                            modY,
                            y,
                            EasingFunctions.Ease(t, mod.falloffEasing)
                        );
                    }
                }

                return y;
            }

            var vertexIndex = 0;
            for (var z = 0; z <= chunkResolution; z++)
            {
                for (var x = 0; x <= chunkResolution; x++)
                {
                    Vector3 GetPos(int queryX, int queryZ)
                    {
                        var adjustedX = queryX * squareSize - halfAChunk;
                        var adjustedZ = queryZ * squareSize - halfAChunk;
                        return new Vector3(
                            adjustedX,
                            GetY(adjustedX, adjustedZ),
                            adjustedZ
                        );
                    }

                    var position = GetPos(x, z);
                    vertices[vertexIndex] = position;

                    uv[vertexIndex] = new Vector2((float) x / chunkResolution, (float) z / chunkResolution);

                    var queryN = GetPos(x, z + 1) - position;
                    var queryE = GetPos(x + 1, z) - position;
                    var queryW = GetPos(x - 1, z) - position;
                    var queryS = GetPos(x, z - 1) - position;

                    var normal =
                        Vector3.Cross(queryN, queryE) +
                        Vector3.Cross(queryE, queryS) +
                        Vector3.Cross(queryS, queryW) +
                        Vector3.Cross(queryW, queryN);

                    normal.Normalize();

                    normals[vertexIndex] = normal;

                    vertexIndex++;
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
            
            _mesh.UploadMeshData(true);

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