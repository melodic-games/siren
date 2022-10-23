using KinematicCharacterController.Examples;
using UnityEngine;

namespace Siren.Scripts.Player
{
    public class SirenPlayer : MonoBehaviour
    {
        public ExampleCharacterCamera orbitCamera;
        public Transform cameraFollowPoint;
        public SirenCharacterController character;
        
        private Vector3 _lookInputVector = Vector3.zero;
        
        private void Start()
        {
            Cursor.lockState = CursorLockMode.Locked;

            // Tell camera to follow transform
            orbitCamera.SetFollowTransform(cameraFollowPoint);

            // Ignore the character's collider(s) for camera obstruction checks
            orbitCamera.IgnoredColliders.Clear();
            orbitCamera.IgnoredColliders.AddRange(character.GetComponentsInChildren<Collider>());
        }
        
        private void Update()
        {
            if (Input.GetMouseButtonDown(0))
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
            var mouseLookAxisUp = Input.GetAxisRaw("Mouse Y");
            var mouseLookAxisRight = Input.GetAxisRaw("Mouse X");
            _lookInputVector = new Vector3(mouseLookAxisRight, mouseLookAxisUp, 0f);

            // Prevent moving the camera while the cursor isn't locked
            if (Cursor.lockState != CursorLockMode.Locked)
            {
                _lookInputVector = Vector3.zero;
            }

            // Input for zooming the camera (disabled in WebGL because it can cause problems)
            var scrollInput = -Input.GetAxis("Mouse ScrollWheel");
#if UNITY_WEBGL
            scrollInput = 0f;
#endif

            // Apply inputs to the camera
            orbitCamera.UpdateWithInput(Time.deltaTime, scrollInput, _lookInputVector);

            // Handle toggling zoom level
            if (Input.GetMouseButtonDown(1))
            {
                orbitCamera.TargetDistance = (orbitCamera.TargetDistance == 0f) ? orbitCamera.DefaultDistance : 0f;
            }
        }

        private void HandleCharacterInput()
        {
            var inputs = new PlayerCharacterInputs
            {
                MoveAxisForward = Input.GetAxisRaw("Vertical"),
                MoveAxisRight = Input.GetAxisRaw("Horizontal"),
                CameraRotation = orbitCamera.transform.rotation
            };

            character.SetInputs(inputs);
        }
    }
}