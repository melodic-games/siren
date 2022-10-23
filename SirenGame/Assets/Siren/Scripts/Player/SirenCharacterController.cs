using KinematicCharacterController;
using UnityEngine;

namespace Siren.Scripts.Player
{
    public struct PlayerCharacterInputs
    {
        public float MoveAxisForward;
        public float MoveAxisRight;
        public Quaternion CameraRotation;
    }

    public class SirenCharacterController : MonoBehaviour, ICharacterController
    {
        public KinematicCharacterMotor motor;

        [Header("Stable Movement")] public float maxStableMoveSpeed = 10f;
        public float stableMovementSharpness = 15;
        public float orientationSharpness = 10;

        [Header("Air Movement")] public float maxAirMoveSpeed = 10f;
        public float airAccelerationSpeed = 5f;
        public float drag = 0.1f;

        [Header("Misc")] public bool rotationObstruction;
        public Vector3 gravity = new(0, -30f, 0);
        public Transform meshRoot;

        private Vector3 _moveInputVector;
        private Vector3 _lookInputVector;

        private void Start()
        {
            motor.CharacterController = this;
        }

        public void SetInputs(PlayerCharacterInputs inputs)
        {
            // clamp input
            var moveInputVector = Vector3.ClampMagnitude(
                new Vector3(inputs.MoveAxisRight, 0f, inputs.MoveAxisForward),
                1f
            );

            // calculate camera direction and rotation on the character plane
            var cameraPlanarDirection = Vector3.ProjectOnPlane(
                inputs.CameraRotation * Vector3.forward, motor.CharacterUp
            ).normalized;

            if (cameraPlanarDirection.sqrMagnitude == 0f)
            {
                cameraPlanarDirection = Vector3.ProjectOnPlane(
                    inputs.CameraRotation * Vector3.up, motor.CharacterUp
                ).normalized;
            }

            var cameraPlanarRotation = Quaternion.LookRotation(cameraPlanarDirection, motor.CharacterUp);

            // move and look inputs
            _moveInputVector = cameraPlanarRotation * moveInputVector;
            _lookInputVector = cameraPlanarDirection;
        }

        public void BeforeCharacterUpdate(float deltaTime)
        {
            // This is called before the motor does anything
        }

        public void UpdateRotation(ref Quaternion currentRotation, float deltaTime)
        {
            // This is called when the motor wants to know what its rotation should be right now

            if (_lookInputVector == Vector3.zero || orientationSharpness <= 0f) return;
            // if (_lookInputVector != Vector3.zero && OrientationSharpness > 0f)

            // smoothly interpolate from current to target look direction
            var smoothedLookInputDirection = Vector3.Slerp(
                motor.CharacterForward,
                _lookInputVector,
                1f - Mathf.Exp(-orientationSharpness * deltaTime)
            ).normalized;

            // set the current rotation which will be used by the KinematicCharacterMotor
            currentRotation = Quaternion.LookRotation(smoothedLookInputDirection, motor.CharacterUp);
        }

        public void UpdateVelocity(ref Vector3 currentVelocity, float deltaTime)
        {
            // This is called when the motor wants to know what its velocity should be right now

            Vector3 targetMovementVelocity;

            if (motor.GroundingStatus.IsStableOnGround)
            {
                // reorient source velocity on current ground slope
                // (this is because we don't want our smoothing to cause any velocity losses in slope changes)
                currentVelocity =
                    motor.GetDirectionTangentToSurface(currentVelocity, motor.GroundingStatus.GroundNormal) *
                    currentVelocity.magnitude;

                // calculate target velocity
                var inputRight = Vector3.Cross(_moveInputVector, motor.CharacterUp);
                var reorientedInput = Vector3.Cross(
                    motor.GroundingStatus.GroundNormal, inputRight
                ).normalized * _moveInputVector.magnitude;

                targetMovementVelocity = reorientedInput * maxStableMoveSpeed;

                // smooth movement velocity
                currentVelocity = Vector3.Lerp(
                    currentVelocity,
                    targetMovementVelocity,
                    1f - Mathf.Exp(-stableMovementSharpness * deltaTime)
                );
            }
            else
            {
                // add move input 
                if (_moveInputVector.sqrMagnitude > 0f)
                {
                    targetMovementVelocity = _moveInputVector * maxAirMoveSpeed;

                    // prevent climbing on un-stable slopes with air movement
                    if (motor.GroundingStatus.FoundAnyGround)
                    {
                        var perpendicularObstructionNormal = Vector3.Cross(
                            Vector3.Cross(
                                motor.CharacterUp,
                                motor.GroundingStatus.GroundNormal
                            ),
                            motor.CharacterUp
                        ).normalized;

                        targetMovementVelocity = Vector3.ProjectOnPlane(
                            targetMovementVelocity,
                            perpendicularObstructionNormal
                        );
                    }

                    var velocityDiff = Vector3.ProjectOnPlane(
                        targetMovementVelocity - currentVelocity, gravity
                    );

                    currentVelocity += velocityDiff * airAccelerationSpeed * deltaTime;
                }
                
                // gravity
                currentVelocity += gravity * deltaTime;
                
                // drag
                currentVelocity *= 1f / (1f + drag * deltaTime);
            }
        }

        public void AfterCharacterUpdate(float deltaTime)
        {
            // This is called after the motor has finished everything in its update
        }

        public bool IsColliderValidForCollisions(Collider coll)
        {
            // This is called after when the motor wants to know if the collider can be collided with (or if we just go through it)
            return true;
        }

        public void OnGroundHit(Collider hitCollider, Vector3 hitNormal, Vector3 hitPoint,
            ref HitStabilityReport hitStabilityReport)
        {
            // This is called when the motor's ground probing detects a ground hit
        }

        public void OnMovementHit(Collider hitCollider, Vector3 hitNormal, Vector3 hitPoint,
            ref HitStabilityReport hitStabilityReport)
        {
            // This is called when the motor's movement logic detects a hit
        }

        public void ProcessHitStabilityReport(Collider hitCollider, Vector3 hitNormal, Vector3 hitPoint,
            Vector3 atCharacterPosition, Quaternion atCharacterRotation, ref HitStabilityReport hitStabilityReport)
        {
            // This is called after every hit detected in the motor, to give you a chance to modify the HitStabilityReport any way you want
        }

        public void PostGroundingUpdate(float deltaTime)
        {
            // This is called after the motor has finished its ground probing, but before PhysicsMover/Velocity/etc.... handling
        }

        public void OnDiscreteCollisionDetected(Collider hitCollider)
        {
            // This is called by the motor when it is detecting a collision that did not result from a "movement hit".
        }
    }
}