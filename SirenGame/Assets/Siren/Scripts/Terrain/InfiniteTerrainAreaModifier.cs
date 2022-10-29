using System;
using Siren.Scripts.Utils;
using UnityEngine;
using UnityEngine.Serialization;

namespace Siren.Scripts.Terrain
{
    public class InfiniteTerrainAreaModifier : MonoBehaviour
    {
        public InfiniteTerrain infiniteTerrain;

        [Header("Modifier")] public float radius = 4;
        public float falloff = 2;

        [Header("Noise"), Range(0.01f, 0.001f)]
        public float noiseSize = 0.005f;

        [Range(0.1f, 300f)] public float noiseHeight = 10;

        private Vector3 _position;

        private Bounds _bounds;

        public void Awake()
        {
            _position = transform.position;
            UpdateBounds();
        }

        private void Update()
        {
            if (Vector3.Distance(_position, transform.position) < 0.01f) return;

            _position = transform.position;
            infiniteTerrain.ReloadAllChunks();

            UpdateBounds();
        }

        private void OnValidate()
        {
            infiniteTerrain.ReloadAllChunks();
        }

        private void UpdateBounds()
        {
            var size = (radius + falloff) * 2;
            _bounds = new Bounds(transform.position, new Vector3(size, 999, size));
        }

        public Bounds GetBounds()
        {
            return _bounds;
        }
        
        public float DistanceFrom(Vector3 position)
        {
            return Vector3.Distance(_position, position);
        }

        public void OnDrawGizmos()
        {
            Gizmos.color = Color.red;
            GizmoUtils.DrawFlatCircleGizmo(transform.position, radius);

            Gizmos.color = Color.yellow;
            GizmoUtils.DrawFlatCircleGizmo(transform.position, radius + falloff / 3);

            Gizmos.color = Color.green;
            GizmoUtils.DrawFlatCircleGizmo(transform.position, radius + falloff / 3 * 2);

            Gizmos.color = Color.blue;
            GizmoUtils.DrawFlatCircleGizmo(transform.position, radius + falloff);

            // GizmoUtils.DrawBounds(_bounds);
        }
    }
}