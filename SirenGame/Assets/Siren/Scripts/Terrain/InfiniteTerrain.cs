using System.Collections.Generic;
using System.Linq;
using System.Threading;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Siren.Scripts.Terrain
{
    [ExecuteInEditMode]
    public class InfiniteTerrain : MonoBehaviour
    {
        // TODO: setting view distance too high makes lag
        
        [Header("General"), Range(1, 32f)] public int viewDistance = 4;
        public Transform playerCharacterTransform;
        public Material terrainMaterial;

        [Header("Generation"), Range(64f, 1024f)]
        public int chunkSize = 500;

        [Range(100, 254)] public int chunkResolution = 254;
        [Range(0.01f, 0.001f)] public float noiseSize = 0.005f;
        [Range(0.1f, 100f)] public float noiseHeight = 10;

        [Header("Area Modifiers")] public InfiniteTerrainAreaModifier[] areaModifiers;

        private readonly Dictionary<Vector2Int, InfiniteTerrainChunk> _chunks = new();
        private readonly object _chunksLock = new();

        private Vector2Int _lastPlayerPosition = new(999999, 999999);

        private Vector2Int[] _currentSortedChunkPositions = { };
        private readonly object _currentSortedChunkPositionsLock = new();

        private Thread[] _meshGenThreads;
        private bool _externalThreadRunning = true;

        private void OnEnable()
        {
            _externalThreadRunning = true;

            _meshGenThreads = new[]
            {
                new Thread(ExternalThread),
                new Thread(ExternalThread)
            };

            foreach (var thread in _meshGenThreads)
            {
                thread.Start();
            }

#if UNITY_EDITOR
            if (!EditorApplication.isPlaying)
            {
                EditorApplication.update += UpdateFn;
            }
#endif
        }

        private void OnDisable()
        {
#if UNITY_EDITOR
            if (!EditorApplication.isPlaying)
            {
                EditorApplication.update -= UpdateFn;
            }
#endif

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

        private void DestroyChunk(InfiniteTerrainChunk chunk)
        {
#if UNITY_EDITOR
            if (EditorApplication.isPlaying)
            {
                Destroy(chunk.gameObject);
            }
            else
            {
                DestroyImmediate(chunk.gameObject);
            }
#else
            Destroy(chunk.gameObject)
#endif
        }

        public void DeleteAllChunks()
        {
            lock (_chunksLock)
            {
                foreach (var chunk in _chunks.Values)
                {
                    DestroyChunk(chunk);
                }

                _chunks.Clear();
            }
        }

        public void ReloadAllChunks()
        {
            lock (_chunksLock)
            {
                foreach (var chunk in _chunks.Values)
                {
                    chunk.ReloadThreadSafe();
                }
            }
        }

        private void OnValidate()
        {
            // when parameters change
            _lastPlayerPosition = new Vector2Int(999, 999);

            // TODO: chunk size changes doesnt work with reload all chunks 

            // DeleteAllChunks();
            ReloadAllChunks();
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
            // could be optimized but works pretty well for now

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
                hideFlags = HideFlags.DontSave
                // hideFlags = HideFlags.HideAndDontSave
            };

            var infiniteTerrainChunk = chunk.AddComponent<InfiniteTerrainChunk>();
            infiniteTerrainChunk.infiniteTerrain = this;
            infiniteTerrainChunk.chunkPosition = chunkPosition;

            return infiniteTerrainChunk;
        }


        private async void ExternalThread()
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

                await chunk.DoExternalThreadWork();
            }
        }

        public void UpdateFn()
        {
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

            // remove chunks not required

            InfiniteTerrainChunk[] chunks;
            lock (_chunksLock)
            {
                chunks = _chunks.Values.ToArray();
            }

            foreach (var chunk in chunks)
            {
                if (_currentSortedChunkPositions.Contains(chunk.chunkPosition)) continue;
                DestroyChunk(chunk);
                lock (_chunksLock)
                {
                    _chunks.Remove(chunk.chunkPosition);
                }
            }
        }

        public void Update()
        {
#if UNITY_EDITOR
            if (!EditorApplication.isPlaying) return;
#endif
            UpdateFn();
        }
    }
}