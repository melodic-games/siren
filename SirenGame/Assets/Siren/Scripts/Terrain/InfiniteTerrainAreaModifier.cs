using Siren.Scripts.UI;
using Siren.Scripts.Utils;
using UnityEngine;

namespace Siren.Scripts.Terrain
{
    [ExecuteInEditMode]
    public class InfiniteTerrainAreaModifier : MonoBehaviour
    {
        public InfiniteTerrain infiniteTerrain;

        [Header("Modifier")] public float radius = 4;
        public float falloff = 2;
        public EasingFunctions.Easing easing = EasingFunctions.Easing.InOutSine;

        public enum BlendMode
        {
            Add,
            Replace
        }

        public BlendMode blendMode = BlendMode.Replace;

        [Header("Noise"), Range(0.01f, 0.001f)]
        public float noiseSize = 0.005f;

        [Range(0.1f, 300f)] public float noiseHeight = 10;

        private Vector3 _position;

        private Bounds _bounds;

        public void OnEnable()
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
            // center y pos is at 0 so y size doesnt matter much
            _bounds = new Bounds(
                new Vector3(transform.position.x, 0, transform.position.z),
                new Vector3(size, 1, size)
            );
        }

        public Bounds GetBounds()
        {
            return _bounds;
        }

        public Vector3 GetPosition()
        {
            return _position;
        }

        public float XZDistanceFrom(Vector3 position)
        {
            return Vector3.Distance(
                new Vector3(_position.x, 0, _position.z),
                new Vector3(position.x, 0, position.z)
            );
        }

        public void OnDrawGizmos()
        {
            var position = transform.position;

            // var steps = falloff / 16f;
            const int steps = 16;

            for (var i = 0; i < steps + 1; i++)
            {
                var t = (float) i / steps;

                var color = Color.HSVToRGB(t, 1, 1);
                Gizmos.color = color;

                GizmoUtils.DrawFlatCircleGizmo(
                    Vector3.Lerp(
                        position,
                        new Vector3(position.x, 0, position.z),
                        EasingFunctions.Ease(t, easing)
                    ),
                    radius + t * falloff
                );
            }

            Gizmos.DrawIcon(
                transform.position + new Vector3(0, noiseHeight, 0),
                "terrain-area-modifier.png",
                false
            );

            // GizmoUtils.DrawBounds(_bounds);
        }
    }
}