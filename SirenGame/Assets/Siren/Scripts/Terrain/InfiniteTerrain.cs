using System.Collections.Generic;
using System.Threading;
using UnityEngine;

namespace Siren.Scripts.Terrain
{
    public class InfiniteTerrain : MonoBehaviour
    {
        [Header("General")] public int viewDistance = 4;
        public Transform playerCharacterTransform;
        public Material terrainMaterial;

        [Header("Generation")] [Range(64f, 512f)]
        public int chunkSize = 500;

        [Range(100, 254)] public int chunkResolution = 254;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeight = 10;

        private readonly Dictionary<Vector2Int, InfiniteTerrainChunk> _chunks = new();

        // private Vector2Int _lastPlayerPosition = new(999, 999);

        private Thread _meshGenThread;
        private bool _meshGenThreadRunning = true;

        private readonly Queue<InfiniteTerrainChunk> _chunksToMeshGen = new();
        private readonly Object _chunksToMeshGenLock = new();

        private const float ChunkUpdateMeshTimeout = 0.05f;
        private float _chunkUpdateMeshTimer = ChunkUpdateMeshTimeout;

        private void Start()
        {
            _meshGenThread = new Thread(MeshGenThread);
            _meshGenThread.Start();
        }

        private void OnDestroy()
        {
            _meshGenThreadRunning = false;
            if (_meshGenThread.IsAlive)
            {
                _meshGenThread.Join();
            }
        }

        private Vector2Int GetPlayerChunkPosition()
        {
            var playerPos = playerCharacterTransform.position;
            return new Vector2Int(
                Mathf.FloorToInt(playerPos.x / chunkSize),
                Mathf.FloorToInt(playerPos.z / chunkSize)
            );
        }

        private List<(Vector2Int, float)> GetSpiralChunkPositionsAroundPlayer(Vector2Int playerChunkPosition)
        {
            // TODO: optimize this!

            var chunkPositions = new List<(Vector2Int, float)>();

            for (var deltaZ = -viewDistance; deltaZ < viewDistance; deltaZ++)
            {
                for (var deltaX = -viewDistance; deltaX < viewDistance; deltaX++)
                {
                    var chunkPosition = playerChunkPosition + new Vector2Int(deltaX, deltaZ);
                    var chunkDistance = Vector2Int.Distance(playerChunkPosition, chunkPosition);
                    if (chunkDistance <= viewDistance)
                    {
                        // in view distance radius
                        chunkPositions.Add((chunkPosition, chunkDistance));
                    }
                }
            }

            chunkPositions.Sort((a, b) => (int) (a.Item2 - b.Item2));

            return chunkPositions;
        }

        private InfiniteTerrainChunk CreateChunkGameObject(Vector2Int chunkPosition)
        {
            var chunk = new GameObject
            {
                name = $"Chunk {chunkPosition.x},{chunkPosition.y}",
                isStatic = true,
                transform =
                {
                    position = new Vector3(chunkPosition.x * chunkSize, 0, chunkPosition.y * chunkSize),
                    parent = transform
                }
            };

            var infiniteTerrainChunk = chunk.AddComponent<InfiniteTerrainChunk>();
            infiniteTerrainChunk.infiniteTerrain = this;
            infiniteTerrainChunk.chunkPosition = chunkPosition;

            return infiniteTerrainChunk;
        }

        private void MeshGenThread()
        {
            while (_meshGenThreadRunning)
            {
                InfiniteTerrainChunk chunkToMeshGen;

                lock (_chunksToMeshGenLock)
                {
                    if (_chunksToMeshGen.Count == 0) continue;
                    chunkToMeshGen = _chunksToMeshGen.Dequeue();
                }

                chunkToMeshGen.GenerateAllMeshData();
            }
        }

        public void Update()
        {
            // TODO: handle changes to parameters by regenerating all chunks

            var playerChunkPosition = GetPlayerChunkPosition();
            // if (playerChunkPosition == _lastPlayerPosition) return;
            // _lastPlayerPosition = playerChunkPosition;

            // search around player with view distance
            var chunkPositionsRequired = GetSpiralChunkPositionsAroundPlayer(playerChunkPosition);

            var canUpdateOneChunkMesh = _chunkUpdateMeshTimer >= ChunkUpdateMeshTimeout;

            foreach (var chunkPosition in chunkPositionsRequired)
            {
                if (_chunks.TryGetValue(chunkPosition.Item1, out var chunk))
                {
                    // if thread generated mesh data but it's not been applied yet (has to be done in main thread)
                    if (canUpdateOneChunkMesh && chunk.allMeshDataGenerated && chunk.allMeshDataApplied == false)
                    {
                        // update mesh and reset timer
                        chunk.UpdateGameObjectMesh();
                        _chunkUpdateMeshTimer -= ChunkUpdateMeshTimeout;
                        canUpdateOneChunkMesh = false;
                    }
                }
                else
                {
                    // make a chunk
                    chunk = CreateChunkGameObject(chunkPosition.Item1);
                    _chunks[chunkPosition.Item1] = chunk;

                    lock (_chunksToMeshGenLock)
                    {
                        _chunksToMeshGen.Enqueue(chunk);
                    }
                }
            }

            _chunkUpdateMeshTimer += Time.deltaTime;

            // TODO: remove chunks not required
        }
    }
}