using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Siren.Scripts.Utils
{
    public class ShowNormals : MonoBehaviour
    {
#if UNITY_EDITOR
        public bool isShowNormal;
        public Color color = Color.yellow;
        public float normalsLength = 1f;

        private void OnDrawGizmosSelected()
        {
            if (!isShowNormal) return;

            if (!TryGetComponent<MeshFilter>(out var meshFilter)) return;

            var mesh = meshFilter.sharedMesh;
            if (mesh == null) return;

            var defaultColor = Handles.color;
            Handles.matrix = transform.localToWorldMatrix;
            Handles.color = color;
            var verts = mesh.vertices;
            var normals = mesh.normals;
            int len = mesh.vertexCount;

            for (int i = 0; i < len; i++)
            {
                Handles.DrawLine(verts[i], verts[i] + normals[i] * normalsLength);
            }

            Handles.color = defaultColor;
        }
#endif
    }
}