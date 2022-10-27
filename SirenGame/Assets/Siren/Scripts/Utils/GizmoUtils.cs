using UnityEngine;

namespace Siren.Scripts.Utils
{
    public static class GizmoUtils
    {
        public static void DrawFlatCircleGizmo(Vector3 position, float radius)
        {
            const float thetaScale = 0.01f;

            var theta = 0f;
            const int size = (int) (1f / thetaScale + 1f);

            var from = Vector3.zero;

            for (var i = 0; i < size; i++)
            {
                theta += 2.0f * Mathf.PI * thetaScale;

                var to = new Vector3(radius * Mathf.Cos(theta), 0, radius * Mathf.Sin(theta));

                if (i == 0)
                {
                    from = to;
                    continue;
                }

                Gizmos.DrawLine(from + position, to + position);

                from = to;
            }
        }

        public static void DrawBounds(Bounds b, float delay = 0)
        {
            // bottom
            var p1 = new Vector3(b.min.x, b.min.y, b.min.z);
            var p2 = new Vector3(b.max.x, b.min.y, b.min.z);
            var p3 = new Vector3(b.max.x, b.min.y, b.max.z);
            var p4 = new Vector3(b.min.x, b.min.y, b.max.z);

            Debug.DrawLine(p1, p2, Color.blue, delay);
            Debug.DrawLine(p2, p3, Color.red, delay);
            Debug.DrawLine(p3, p4, Color.yellow, delay);
            Debug.DrawLine(p4, p1, Color.magenta, delay);

            // top
            var p5 = new Vector3(b.min.x, b.max.y, b.min.z);
            var p6 = new Vector3(b.max.x, b.max.y, b.min.z);
            var p7 = new Vector3(b.max.x, b.max.y, b.max.z);
            var p8 = new Vector3(b.min.x, b.max.y, b.max.z);

            Debug.DrawLine(p5, p6, Color.blue, delay);
            Debug.DrawLine(p6, p7, Color.red, delay);
            Debug.DrawLine(p7, p8, Color.yellow, delay);
            Debug.DrawLine(p8, p5, Color.magenta, delay);

            // sides
            Debug.DrawLine(p1, p5, Color.white, delay);
            Debug.DrawLine(p2, p6, Color.gray, delay);
            Debug.DrawLine(p3, p7, Color.green, delay);
            Debug.DrawLine(p4, p8, Color.cyan, delay);
        }
    }
}