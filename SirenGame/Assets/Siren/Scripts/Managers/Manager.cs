using System.Threading.Tasks;

namespace Siren.Scripts.Managers
{
    public class Manager
    {
        public virtual Task Init()
        {
            return Task.CompletedTask;
        }

        public virtual void Update()
        {
            
        }

        public virtual void OnDestroy()
        {
            
        }
    }
}