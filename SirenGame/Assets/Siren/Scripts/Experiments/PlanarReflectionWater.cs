using UnityEngine;

[ExecuteInEditMode]
public class PlanarReflectionWater : MonoBehaviour
{
    private Camera _mirrorCamera;
    private Skybox _mirrorSkybox;

    private RenderTexture _renderTexture;

    private MeshRenderer _meshRenderer;


    private static readonly int MainTexShaderId = Shader.PropertyToID("_MainTex");

    void OnEnable()
    {
        _renderTexture = RenderTexture.GetTemporary(1024, 1024);

        _meshRenderer = GetComponent<MeshRenderer>();
        _meshRenderer.material.SetTexture(MainTexShaderId, _renderTexture);
    }

    void OnDisable()
    {
        if (_mirrorCamera != null)
        {
            if (Application.isEditor)
            {
                DestroyImmediate(_mirrorCamera.gameObject);
            }
            else
            {
                Destroy(_mirrorCamera.gameObject);
            }

            _mirrorCamera = null;
            _mirrorSkybox = null;
        }

        if (_renderTexture != null)
        {
            RenderTexture.ReleaseTemporary(_renderTexture);
        }

        _meshRenderer = null;
    }

    private Vector3 GetPlanePosition()
    {
        var pos = transform.position;
        pos.y += _meshRenderer.bounds.size.y / 2;
        return pos;
    }

    private Vector3 GetPlaneNormal()
    {
        return transform.up;
    }

    private static Vector4 Plane(Vector3 position, Vector3 normal) =>
        new(normal.x, normal.y, normal.z, -Vector3.Dot(position, normal));

    private static Vector4 CameraSpacePlane(Camera camera, Vector3 position, Vector3 normal)
    {
        var worldToCameraMatrix = camera.worldToCameraMatrix;
        return Plane(worldToCameraMatrix.MultiplyPoint(position),
            worldToCameraMatrix.MultiplyVector(normal).normalized);
    }

    private static Matrix4x4 CalculateReflectionMatrix(Vector4 plane)
    {
        Matrix4x4 m;
        m.m00 = (float)(1.0 - 2.0 * plane[0] * plane[0]);
        m.m01 = -2f * plane[0] * plane[1];
        m.m02 = -2f * plane[0] * plane[2];
        m.m03 = -2f * plane[3] * plane[0];
        m.m10 = -2f * plane[1] * plane[0];
        m.m11 = (float)(1.0 - 2.0 * plane[1] * plane[1]);
        m.m12 = -2f * plane[1] * plane[2];
        m.m13 = -2f * plane[3] * plane[1];
        m.m20 = -2f * plane[2] * plane[0];
        m.m21 = -2f * plane[2] * plane[1];
        m.m22 = (float)(1.0 - 2.0 * plane[2] * plane[2]);
        m.m23 = -2f * plane[3] * plane[2];
        m.m30 = 0.0f;
        m.m31 = 0.0f;
        m.m32 = 0.0f;
        m.m33 = 1f;
        return m;
    }

    private void UpdateMirrorCamera(Camera src, RenderTexture targetTexture)
    {
        if (!_mirrorCamera)
        {
            var mirrorCameraGameObject =
                new GameObject(
                    "Mirror Camera", typeof(Camera), typeof(Skybox), typeof(FlareLayer)
                )
                {
                    hideFlags = HideFlags.HideAndDontSave
                };
            _mirrorSkybox = mirrorCameraGameObject.GetComponent<Skybox>();
            _mirrorCamera = mirrorCameraGameObject.GetComponent<Camera>();
            _mirrorCamera.enabled = false;
        }

        _mirrorCamera.clearFlags = src.clearFlags;
        _mirrorCamera.backgroundColor = src.backgroundColor;
        if (src.clearFlags == CameraClearFlags.Skybox)
        {
            var skybox = src.GetComponent<Skybox>();
            if (!skybox || !skybox.material)
            {
                _mirrorSkybox.enabled = false;
            }
            else
            {
                _mirrorSkybox.enabled = true;
                _mirrorSkybox.material = skybox.material;
            }
        }

        _mirrorCamera.farClipPlane = src.farClipPlane;
        _mirrorCamera.nearClipPlane = src.nearClipPlane;
        _mirrorCamera.orthographic = src.orthographic;
        _mirrorCamera.aspect = src.aspect;
        _mirrorCamera.orthographicSize = src.orthographicSize;
        _mirrorCamera.useOcclusionCulling = false; // hmm
        _mirrorCamera.allowMSAA = src.allowMSAA;
        if (src.stereoEnabled) return;
        _mirrorCamera.fieldOfView = src.fieldOfView;

        _mirrorCamera.ResetWorldToCameraMatrix();
        _mirrorCamera.transform.position = src.transform.position;
        _mirrorCamera.transform.rotation = src.transform.rotation;
        // _mirrorCamera.projectionMatrix = cameraProjectionMatrix;
        // _mirrorCamera.cullingMask = -17 & ~(1 << _playerLocalLayer) & reflectLayers.value;
        _mirrorCamera.targetTexture = targetTexture;

        _mirrorCamera.worldToCameraMatrix *= CalculateReflectionMatrix(
            Plane(GetPlanePosition(), GetPlaneNormal())
        );

        _mirrorCamera.projectionMatrix =
            _mirrorCamera.CalculateObliqueMatrix(
                CameraSpacePlane(_mirrorCamera, GetPlanePosition(), GetPlaneNormal())
            );

        // _mirrorCamera.transform.position = GetPosition(_mirrorCamera.cameraToWorldMatrix);
        // _mirrorCamera.transform.rotation = GetRotation(_mirrorCamera.cameraToWorldMatrix);

        var num = GL.invertCulling ? 1 : 0;
        GL.invertCulling = num == 0;
        _mirrorCamera.Render();
        GL.invertCulling = num != 0;
    }

    private void OnWillRenderObject()
    {
        var currentCamera = Camera.current;
        if (!currentCamera || currentCamera == _mirrorCamera) return;

        UpdateMirrorCamera(currentCamera, _renderTexture);

        // _propertyBlock.SetTexture(MainTexShaderId, _renderTexture);
    }
}