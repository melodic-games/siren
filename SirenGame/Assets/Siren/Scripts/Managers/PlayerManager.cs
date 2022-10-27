using System.Threading.Tasks;
using Siren.Scripts.Player;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Siren.Scripts.Managers
{
    public class PlayerManager : Manager
    {
        private readonly SirenPlayer _player;

        private SirenInputActions _inputActions;

        public PlayerManager(SirenPlayer player)
        {
            _player = player;
        }

        public override Task Init()
        {
            _inputActions = new SirenInputActions();
            _inputActions.Enable();
            _inputActions.UI.Enable();
            _inputActions.UI.Reset.Enable();
            _inputActions.UI.Reset.performed += OnReset;

            return Task.CompletedTask;
        }

        public override void OnDestroy()
        {
            _inputActions.Disable();
        }

        public void MoveCurrentCharacter(Vector3 position)
        {
            _player.character.motor.SetPosition(position);
            _player.character.resetVelocity = true;
        }

        private void OnReset(InputAction.CallbackContext obj)
        {
            MoveCurrentCharacter(new Vector3(0, 8, 0));
        }
    }
}