using UnityEngine;

namespace Siren.Scripts.Player
{
    public class SirenPlayer : MonoBehaviour
    {
        public SirenCharacterCamera orbitCamera;
        public Transform cameraFollowPoint;
        public SirenCharacterController character;

        private Vector3 _lookInputVector = Vector3.zero;

        private SirenInputActions _inputActions;

        private void Start()
        {
            Cursor.lockState = CursorLockMode.Locked;

            // Tell camera to follow transform
            orbitCamera.SetFollowTransform(cameraFollowPoint);

            // Ignore the character's collider(s) for camera obstruction checks
            orbitCamera.IgnoredColliders.Clear();
            orbitCamera.IgnoredColliders.AddRange(character.GetComponentsInChildren<Collider>());

            _inputActions = new SirenInputActions();
            _inputActions.Enable();
            _inputActions.Player.Enable();
            _inputActions.Player.Move.Enable();
            _inputActions.Player.Look.Enable();
            _inputActions.Player.Scroll.Enable();
            _inputActions.Player.Focus.Enable();
            _inputActions.Player.Jump.Enable();
        }

        private void Update()
        {
            if (_inputActions.Player.Focus.ReadValue<float>() > 0)
            {
                Cursor.lockState = CursorLockMode.Locked;
            }

            HandleCharacterInput();
        }

        private void LateUpdate()
        {
            HandleCameraInput();
        }

        private void HandleCameraInput()
        {
            // Create the look input vector for the camera
            var mouseLook = _inputActions.Player.Look.ReadValue<Vector2>() * 0.1f;

            _lookInputVector = new Vector3(mouseLook.x, mouseLook.y, 0f);

            // Prevent moving the camera while the cursor isn't locked
            if (Cursor.lockState != CursorLockMode.Locked)
            {
                _lookInputVector = Vector3.zero;
            }

            // Input for zooming the camera (disabled in WebGL because it can cause problems)
            // var scrollInput = -Input.GetAxis("Mouse ScrollWheel");
            var scrollInput = -Mathf.Clamp(
                _inputActions.Player.Scroll.ReadValue<Vector2>().y,
                -0.25f, 0.25f
            );
#if UNITY_WEBGL
            scrollInput = 0f;
#endif

            // Apply inputs to the camera
            orbitCamera.UpdateWithInput(Time.deltaTime, scrollInput, _lookInputVector);

            // Handle toggling zoom level
            // if (Input.GetMouseButtonDown(1))
            // {
            //     orbitCamera.TargetDistance = (orbitCamera.TargetDistance == 0f) ? orbitCamera.DefaultDistance : 0f;
            // }
        }

        private void HandleCharacterInput()
        {
            var moveInput = _inputActions.Player.Move.ReadValue<Vector2>();
            var inputs = new PlayerCharacterInputs
            {
                MoveAxisForward = moveInput.y,
                MoveAxisRight = moveInput.x,
                CameraRotation = orbitCamera.transform.rotation,
                JumpDown = _inputActions.Player.Jump.ReadValue<float>() > 0f
            };

            character.SetInputs(inputs);
        }
    }
}