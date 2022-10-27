using System.Collections.Generic;
using System.Linq;
using System.Threading;
using UnityEngine;
using UnityEngine.Serialization;

namespace Siren.Scripts.Terrain
{
    // [ExecuteInEditMode]
    public class InfiniteTerrain : MonoBehaviour
    {
        [Header("General"), Range(1, 32f)] public int viewDistance = 4;
        public Transform playerCharacterTransform;
        public Material terrainMaterial;

        [Header("Generation"), Range(64f, 512f)]
        public int chunkSize = 500;

        [Range(100, 254)] public int chunkResolution = 254;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeight = 10;

        [Header("Area Modifiers")] public InfiniteTerrainAreaModifier[] areaModifiers;

        private readonly Dictionary<Vector2Int, InfiniteTerrainChunk> _chunks = new();
        private readonly Object _chunksLock = new();

        private Vector2Int _lastPlayerPosition = new(999, 999);

        private Vector2Int[] _currentSortedChunkPositions = { };
        private readonly Object _currentSortedChunkPositionsLock = new();

        private Thread[] _meshGenThreads;
        private bool _externalThreadRunning = true;

        private void Start()
        {
            _meshGenThreads = new[]
            {
                new Thread(ExternalThread),
                new Thread(ExternalThread)
            };

            foreach (var thread in _meshGenThreads)
            {
                thread.Start();
            }
        }

        private void OnDestroy()
        {
            _externalThreadRunning = false;

            foreach (var thread in _meshGenThreads)
            {
                if (thread.IsAlive)
                {
                    thread.Join();
                }
            }

            DeleteAllChunks();
        }

        public void DeleteAllChunks()
        {
            lock (_chunksLock)
            {
                foreach (var chunk in _chunks.Values)
                {
                    Destroy(chunk.gameObject);
                }

                _chunks.Clear();
            }
        }

        private void OnValidate()
        {
            // when parameters change
            _lastPlayerPosition = new Vector2Int(999, 999);

            DeleteAllChunks();

            // TODO: actually make this work so we can mark chunks dirty
            // currently, external thread might be busy generating whilst this gets set

            // lock (_chunksLock)
            // {
            //     foreach (var chunk in _chunks.Values)
            //     {
            //         chunk.status = ChunkStatus.NeedMeshGen;
            //     }
            // }
        }

        public InfiniteTerrainAreaModifier[] GetAreaModifiersInBounds(Bounds bounds)
        {
            return areaModifiers
                .Where(m => m.GetBounds().Intersects(bounds))
                .ToArray();
        }

        private void SetThreadSafeChunk(Vector2Int position, InfiniteTerrainChunk chunk)
        {
            lock (_chunksLock)
            {
                _chunks[position] = chunk;
            }
        }

        private InfiniteTerrainChunk GetThreadSafeChunk(Vector2Int position)
        {
            lock (_chunksLock)
            {
                return _chunks.TryGetValue(position, out var chunk) ? chunk : null;
            }
        }

        private Vector2Int GetPlayerChunkPosition()
        {
            var playerPos = playerCharacterTransform.position;
            var halfAChunk = chunkSize * 0.5f;
            return new Vector2Int(
                Mathf.FloorToInt(playerPos.x + halfAChunk) / chunkSize,
                Mathf.FloorToInt(playerPos.z + halfAChunk) / chunkSize
            );
        }

        private Vector2Int[] GetSpiralChunkPositionsAroundPlayer(Vector2Int playerChunkPosition)
        {
            // TODO: optimize this!

            var chunkPositions = new List<(Vector2Int, float)>();

            for (var deltaZ = -viewDistance; deltaZ < viewDistance; deltaZ++)
            {
                for (var deltaX = -viewDistance; deltaX < viewDistance; deltaX++)
                {
                    var chunkPosition = playerChunkPosition + new Vector2Int(deltaX, deltaZ);
                    var chunkDistance = Vector2.Distance(playerChunkPosition, chunkPosition);
                    if (chunkDistance < viewDistance)
                    {
                        // in view distance radius
                        chunkPositions.Add((chunkPosition, chunkDistance));
                    }
                }
            }

            chunkPositions.Sort((a, b) => a.Item2.CompareTo(b.Item2));

            return chunkPositions.Select(tuple => tuple.Item1).ToArray();
        }

        private InfiniteTerrainChunk CreateChunkGameObject(Vector2Int chunkPosition)
        {
            var position = new Vector3(
                chunkPosition.x * chunkSize,
                0,
                chunkPosition.y * chunkSize
            );

            var chunk = new GameObject
            {
                name = $"Chunk {chunkPosition.x},{chunkPosition.y}",
                isStatic = true,
                transform =
                {
                    position = position,
                    parent = transform
                },
                // hideFlags = HideFlags.HideAndDontSave
            };

            var infiniteTerrainChunk = chunk.AddComponent<InfiniteTerrainChunk>();
            infiniteTerrainChunk.infiniteTerrain = this;
            infiniteTerrainChunk.chunkPosition = chunkPosition;

            return infiniteTerrainChunk;
        }

        private void ExternalThread()
        {
            while (_externalThreadRunning)
            {
                // find closest chunk that needs work

                Vector2Int[] currentSortedChunkPositions;
                lock (_currentSortedChunkPositionsLock)
                {
                    currentSortedChunkPositions = _currentSortedChunkPositions;
                }

                InfiniteTerrainChunk chunk = null;

                foreach (var position in currentSortedChunkPositions)
                {
                    var queryChunk = GetThreadSafeChunk(position);
                    if (
                        queryChunk == null ||
                        queryChunk.doingExternalThreadWork ||
                        queryChunk.status is not (ChunkStatus.NeedMeshGen or ChunkStatus.NeedPhysicsBake)
                    ) continue;
                    chunk = queryChunk;
                    break;
                }

                if (chunk == null) continue;

                chunk.DoExternalThreadWork();
            }
        }

        public void Update()
        {
            // TODO: make sure its really rendering the ones closest to the player first

            var playerChunkPosition = GetPlayerChunkPosition();
            if (playerChunkPosition != _lastPlayerPosition)
            {
                var currentSortedChunkPositions = GetSpiralChunkPositionsAroundPlayer(playerChunkPosition);
                lock (_currentSortedChunkPositionsLock)
                {
                    _currentSortedChunkPositions = currentSortedChunkPositions;
                }

                _lastPlayerPosition = playerChunkPosition;
            }

            // search around player with view distance

            var canUpdateOneChunk = true;

            foreach (var chunkPosition in _currentSortedChunkPositions)
            {
                var chunk = GetThreadSafeChunk(chunkPosition);
                if (chunk != null)
                {
                    // if thread generated mesh data but it's not been applied yet (has to be done in main thread)
                    if (canUpdateOneChunk && chunk.status is ChunkStatus.GotMeshGen or ChunkStatus.GotPhysicsBake)
                    {
                        chunk.DoMainThreadWork();
                        canUpdateOneChunk = false;
                    }
                }
                else
                {
                    // make a chunk
                    chunk = CreateChunkGameObject(chunkPosition);
                    SetThreadSafeChunk(chunkPosition, chunk);
                }
            }

            // TODO: remove chunks not required
        }
    }
}