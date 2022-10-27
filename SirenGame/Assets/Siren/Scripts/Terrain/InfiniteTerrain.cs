using System.Collections.Generic;
using System.Threading;
using UnityEngine;

namespace Siren.Scripts.Terrain
{
    // [ExecuteInEditMode]
    public class InfiniteTerrain : MonoBehaviour
    {
        [Header("General")] public int viewDistance = 4;
        public Transform playerCharacterTransform;
        public Material terrainMaterial;

        [Header("Generation"), Range(64f, 512f)]
        public int chunkSize = 500;

        [Range(100, 254)] public int chunkResolution = 254;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeight = 10;

        private readonly Dictionary<Vector2Int, InfiniteTerrainChunk> _chunks = new();
        private readonly Object _chunksLock = new();

        private Vector2Int _lastPlayerPosition = new(999, 999);

        private Thread _meshGenThread;
        private bool _externalThreadRunning = true;

        // private const float ChunkMainThreadUpdateTimeout = 0.05f;
        // private float _chunkMainThreadUpdateTimer = ChunkMainThreadUpdateTimeout;

        private void Start()
        {
            _meshGenThread = new Thread(ExternalThread);
            _meshGenThread.Start();
        }

        private void OnDestroy()
        {
            _externalThreadRunning = false;
            if (_meshGenThread.IsAlive)
            {
                _meshGenThread.Join();
            }

            DeleteAllChunks();
        }

        private void DeleteAllChunks()
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
            DeleteAllChunks();
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
#if UNITY_EDITOR
            var playerPos = Camera.main.transform.position;
#else
            var playerPos = playerCharacterTransform.position;
#endif
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
                },
                // TODO: only doing this for performance reasons, remove somehow
                hideFlags = HideFlags.HideAndDontSave
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

                var playerChunkPosition = _lastPlayerPosition;
                var chunkPositions = GetSpiralChunkPositionsAroundPlayer(playerChunkPosition);

                InfiniteTerrainChunk chunk = null;

                foreach (var position in chunkPositions)
                {
                    var queryChunk = GetThreadSafeChunk(position.Item1);
                    if (
                        queryChunk == null ||
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
            _lastPlayerPosition = playerChunkPosition;

            // search around player with view distance
            var chunkPositionsRequired = GetSpiralChunkPositionsAroundPlayer(playerChunkPosition);

            // var canUpdateOneChunk = _chunkMainThreadUpdateTimer >= ChunkMainThreadUpdateTimeout;
            var canUpdateOneChunk = true;

            foreach (var chunkPosition in chunkPositionsRequired)
            {
                var chunk = GetThreadSafeChunk(chunkPosition.Item1);
                if (chunk != null)
                {
                    // if thread generated mesh data but it's not been applied yet (has to be done in main thread)
                    if (canUpdateOneChunk && chunk.status is ChunkStatus.GotMeshGen or ChunkStatus.GotPhysicsBake)
                    {
                        chunk.DoMainThreadWork();
                        // _chunkMainThreadUpdateTimer -= ChunkMainThreadUpdateTimeout;
                        canUpdateOneChunk = false;
                    }
                }
                else
                {
                    // make a chunk
                    chunk = CreateChunkGameObject(chunkPosition.Item1);
                    SetThreadSafeChunk(chunkPosition.Item1, chunk);
                }
            }

            // nevermind.. time scale affects this value which is probably an unintended side effects
            // _chunkMainThreadUpdateTimer += Time.deltaTime;
            // Debug.Log(_chunkMainThreadUpdateTimer);

            // TODO: remove chunks not required
        }
    }
}