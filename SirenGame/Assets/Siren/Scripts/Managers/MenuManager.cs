using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Siren.Scripts.Managers
{
    public class MenuManager : Manager
    {
        private bool _paused;
        private float _timeScaleBeforePause;
        private CursorLockMode _cursorLockModeBeforePause;

        private readonly GameObject _menuUICanvasPrefab;
        private Canvas _menuUICanvas;

        private SirenInputActions _inputActions;

        public MenuManager(GameObject menuUICanvasPrefab)
        {
            _menuUICanvasPrefab = menuUICanvasPrefab;
        }

        public override Task Init()
        {
            var menuUIGameObject = Object.Instantiate(_menuUICanvasPrefab);
            menuUIGameObject.SetActive(false);

            _menuUICanvas = menuUIGameObject.GetComponentInChildren<Canvas>();

            _inputActions = new SirenInputActions();
            _inputActions.UI.Enable();
            _inputActions.UI.Pause.Enable();
            _inputActions.UI.Pause.performed += OnPausePressed;

            return Task.CompletedTask;
        }

        public void Pause()
        {
            if (_paused) return;

            _timeScaleBeforePause = Time.timeScale;
            Time.timeScale = 0;

            _cursorLockModeBeforePause = Cursor.lockState;
            Cursor.lockState = CursorLockMode.None;

            _menuUICanvas.gameObject.SetActive(true);

            _paused = true;
        }

        public void Play()
        {
            if (!_paused) return;

            Time.timeScale = _timeScaleBeforePause;

            Cursor.lockState = _cursorLockModeBeforePause;

            _menuUICanvas.gameObject.SetActive(false);

            _paused = false;
        }

        private void OnPausePressed(InputAction.CallbackContext obj)
        {
            if (_paused)
            {
                Play();
            }
            else
            {
                Pause();
            }
        }
    }
}