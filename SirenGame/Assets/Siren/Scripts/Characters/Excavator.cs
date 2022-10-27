using UnityEngine;

namespace Siren.Scripts.Characters
{
    [RequireComponent(typeof(Rigidbody))]
    public class Excavator : MonoBehaviour
    {
        private Transform _myTransform;
        private Rigidbody _rb;
   
        void Start()
        {
            _myTransform = GetComponent<Transform>();
            _rb = GetComponent<Rigidbody>();
        }

      
        void FixedUpdate()
        {
            _rb.AddForce(_myTransform.forward * 10,ForceMode.Acceleration);
            
            
        }
    }
}
