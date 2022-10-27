using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Siren.Scripts.Player;
using UnityEngine;

namespace Siren.Scripts.Managers
{
    public class DependencyManager : MonoBehaviour
    {
        public static DependencyManager Instance;

        public MenuManager MenuManager;
        [Header("Menu")] public GameObject menuUICanvasPrefab;

        public PlayerManager PlayerManager;
        [Header("Player")] public SirenPlayer player;

        private Manager[] _managers;
        private bool _initialized;

        private async void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);

            var managers = new List<Manager>();

            managers.Add(MenuManager = new MenuManager(menuUICanvasPrefab));

            managers.Add(PlayerManager = new PlayerManager(player));

            _managers = managers.ToArray();

            await Task.WhenAll(_managers.Select(m => m.Init()));

            _initialized = true;
        }

        private void Update()
        {
            if (!_initialized) return;
            foreach (var manager in _managers)
            {
                manager.Update();
            }
        }

        private void OnDestroy()
        {
            if (!_initialized) return;
            foreach (var manager in _managers)
            {
                manager.Update();
            }
        }
    }
}