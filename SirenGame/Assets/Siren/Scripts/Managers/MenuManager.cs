using System.Threading.Tasks;
using Siren.Scripts.UI;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Siren.Scripts.Managers
{
    public class MenuManager : Manager
    {
        private readonly TweenManager _tweenManager = new();

        private bool _paused;
        private float _timeScaleBeforePause;
        private CursorLockMode _cursorLockModeBeforePause;

        private readonly GameObject _menuUICanvasPrefab;
        private Canvas _menuUICanvas;

        private CanvasGroup _pauseScreenCanvasGroup;
        private RectTransform _pauseIcon;

        // private const float PauseIconYDistance = 15f;
        private const float PauseIconIntScale = .6f;

        private TweenManager.Tweener _pauseScreenOpacity;
        //private TweenManager.Tweener _pauseIconY;
        private TweenManager.Tweener _pauseIconScale;

        private TweenManager.Tweener _timeScale;

        private SirenInputActions _inputActions;

        public MenuManager(GameObject menuUICanvasPrefab)
        {
            _menuUICanvasPrefab = menuUICanvasPrefab;
        }

        public override Task Init()
        {
            var menuUIGameObject = Object.Instantiate(_menuUICanvasPrefab);
            // menuUIGameObject.SetActive(false);

            _menuUICanvas = menuUIGameObject.GetComponentInChildren<Canvas>();

            // init pause menu tweeners

            // TODO: theres a better way to do this
            _pauseScreenCanvasGroup = _menuUICanvas.transform.Find("Pause Screen").GetComponent<CanvasGroup>();
            _pauseIcon = _pauseScreenCanvasGroup.transform.Find("Pause Icon")
                .GetComponent<RectTransform>();

            _pauseScreenOpacity = _tweenManager.NewTweener(
                alpha => { _pauseScreenCanvasGroup.alpha = alpha; },
                0f
            );

            // _pauseIconY = _tweenManager.NewTweener(
            //     y => { _pauseIcon.anchoredPosition = new Vector2(_pauseIcon.anchoredPosition.x, y); },
            //     -PauseIconYDistance
            // );

            _pauseIconScale = _tweenManager.NewTweener(
                scale => { _pauseIcon.localScale = new Vector3(scale, scale, scale); },
                PauseIconIntScale
            );

            _timeScale = _tweenManager.NewTweener(
                timeScale => { Time.timeScale = timeScale; },
                1f
            );

            // init input

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
            _timeScale.Tween(0f, 200f, EasingFunctions.Easing.OutQuad);

            _cursorLockModeBeforePause = Cursor.lockState;
            Cursor.lockState = CursorLockMode.None;

            // _menuUICanvas.gameObject.SetActive(true);
            _pauseScreenOpacity.Tween(1f, 200f, EasingFunctions.Easing.OutQuad);
            // _pauseIconY.Tween(0, 300f, EasingFunctions.Easing.OutQuad);
            _pauseIconScale.Tween(1f, 250f, EasingFunctions.Easing.OutQuad);

            _paused = true;
        }

        public void Play()
        {
            if (!_paused) return;

            _timeScale.Tween(_timeScaleBeforePause, 100f, EasingFunctions.Easing.OutQuad);

            Cursor.lockState = _cursorLockModeBeforePause;

            // _menuUICanvas.gameObject.SetActive(false);
            _pauseScreenOpacity.Tween(0f, 100f, EasingFunctions.Easing.OutQuad);
            //_pauseIconY.Tween(-PauseIconYDistance, 200f, EasingFunctions.Easing.OutQuad);
            _pauseIconScale.Tween(PauseIconIntScale, 200f, EasingFunctions.Easing.OutQuad);

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

        public override void Update()
        {
            _tweenManager.Update();
        }
    }
}